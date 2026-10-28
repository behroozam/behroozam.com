# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'cgi'
require 'openssl'
require 'time'

ENV['MEDIUM_USERNAME'] ||= 'behroozam'

module Jekyll
  class RecommendationFetcher < Generator
    safe true
    priority :high

    USER_AGENT = 'JekyllRecommendationFetcher/1.0 (https://behroozam.com; contact@behroozam.com)'

    def generate(site)
      recommendations = site.data['recommendations']
      return unless recommendations.is_a?(Array) && !recommendations.empty?

      cache_path = File.join(site.source, '_data', 'recommendations_cache.json')
      cache = load_cache(cache_path)
      cache_updated = false

      recommendations.each do |item|
        url = item['url'].to_s.strip
        google_books_id = item['google_books_id'].to_s.strip

        # Determine cache key and fetch strategy
        cache_key = nil
        cache_lookup_keys = []
        if !google_books_id.empty?
          cache_key = "google_books:#{google_books_id}"
          cache_lookup_keys << cache_key
          cache_lookup_keys << "https://books.google.com/books?id=#{google_books_id}"
          cache_lookup_keys << url unless url.empty?
        elsif !url.empty?
          cache_key = url
          cache_lookup_keys << url
        else
          next
        end

        cached_meta = nil
        cache_lookup_keys.each do |candidate_key|
          next unless cache[candidate_key] && !cache[candidate_key]['title'].to_s.empty?

          cached_meta = cache[candidate_key]
          break
        end

        # Fetch metadata if not in cache or if cached metadata is empty
        unless cached_meta
          Jekyll.logger.info "RecommendationFetcher:", "Fetching metadata for #{cache_key}"
          meta = if !google_books_id.empty?
            fetch_google_books_metadata(google_books_id)
          else
            fetch_metadata(url)
          end
          if meta
            cache[cache_key] = meta
            cache[url] = meta if !url.empty? && (url.include?('books.google.com') || url.include?('books.google.'))
            cache_updated = true
          end

          cached_meta = cache[cache_key] || {}
          if cached_meta.empty? && !url.empty?
            cached_meta = cache[url] || {}
          end
        end

        # Merge cached metadata into item, allowing explicit YAML overrides
        item['title'] ||= cached_meta['title'] || (url.empty? ? '' : default_title_from_url(url))
        item['description'] ||= cached_meta['description'] || ''
        item['image'] ||= cached_meta['image'] || ''
        item['authors'] ||= cached_meta['authors'] || ''
        item['site_name'] ||= cached_meta['site_name'] || (url.empty? ? 'Google Books' : site_name_from_url(url))
        item['canonical_url'] ||= cached_meta['canonical_url'] || url
      end

      # Expose enriched cache back to site data
      site.data['recommendations_cache'] = cache
      save_cache(cache_path, cache) if cache_updated
    end

    private

    def load_cache(path)
      return {} unless File.exist?(path)
      begin
        JSON.parse(File.read(path))
      rescue StandardError => e
        Jekyll.logger.warn "RecommendationFetcher:", "Could not parse cache file: #{e.message}"
        {}
      end
    end

    def save_cache(path, cache)
      begin
        File.write(path, JSON.pretty_generate(cache))
        Jekyll.logger.info "RecommendationFetcher:", "Updated metadata cache at #{path}"
      rescue StandardError => e
        Jekyll.logger.warn "RecommendationFetcher:", "Failed to save cache file: #{e.message}"
      end
    end

    def fetch_metadata(url)
      uri = URI.parse(url)
      host = uri.host.to_s.downcase
      if host.include?('wikipedia.org')
        fetch_wikipedia_metadata(url)
      elsif host.include?('books.google.')
        # Extract volume ID from ?id= query parameter
        params = CGI.parse(uri.query.to_s)
        vol_id = params['id']&.first || uri.path.split('/').last
        vol_id && !vol_id.empty? ? fetch_google_books_metadata(vol_id) : fetch_opengraph_metadata(url)
      else
        fetch_opengraph_metadata(url)
      end
    rescue StandardError => e
      Jekyll.logger.warn "RecommendationFetcher:", "Error fetching #{url}: #{e.message}"
      nil
    end

    def fetch_google_books_metadata(volume_id)
      api_url = "https://www.googleapis.com/books/v1/volumes/#{CGI.escape(volume_id)}"
      response_body = http_get(api_url)
      return nil if response_body.nil?

      data = JSON.parse(response_body)
      volume_info = data['volumeInfo'] || {}

      return nil if volume_info['title'].nil?

      # Build high-res thumbnail: prefer large, then thumbnail, then smallThumbnail
      image_links = volume_info['imageLinks'] || {}
      raw_image = image_links['large'] ||
                  image_links['medium'] ||
                  image_links['thumbnail'] ||
                  image_links['smallThumbnail'] || ''
      # Google Books thumbnails use http by default — upgrade to https
      image_url = raw_image.sub(/\Ahttp:/, 'https:')
      # Remove edge=curl zoom parameters for cleaner image
      image_url = image_url.gsub(/[&?]edge=curl/, '').gsub(/[&?]zoom=\d+/, '')

      authors = Array(volume_info['authors']).join(', ')
      canonical = "https://books.google.com/books?id=#{CGI.escape(volume_id)}"

      {
        'title'        => volume_info['title'],
        'authors'      => authors,
        'description'  => volume_info['description'] || volume_info['subtitle'] || '',
        'image'        => image_url,
        'site_name'    => 'Google Books',
        'canonical_url'=> canonical,
        'publisher'    => volume_info['publisher'] || '',
        'published_date' => volume_info['publishedDate'] || '',
        'fetched_at'   => Time.now.iso8601
      }
    rescue StandardError => e
      Jekyll.logger.warn "RecommendationFetcher:", "Google Books API failed for #{volume_id}: #{e.message}"
      nil
    end

    def fetch_wikipedia_metadata(url)
      uri = URI.parse(url)
      host_parts = uri.host.split('.')
      lang = host_parts.first || 'en'
      path_parts = uri.path.split('/')
      page_title = path_parts.last

      return nil if page_title.nil? || page_title.empty?

      api_url = "https://#{lang}.wikipedia.org/api/rest_v1/page/summary/#{CGI.escape(page_title)}"
      response_body = http_get(api_url)
      return fetch_opengraph_metadata(url) if response_body.nil?

      data = JSON.parse(response_body)
      return fetch_opengraph_metadata(url) if data['title'].nil?

      image_url = nil
      if data['thumbnail'] && data['thumbnail']['source']
        image_url = data['thumbnail']['source']
      elsif data['originalimage'] && data['originalimage']['source']
        image_url = data['originalimage']['source']
      end

      canonical_url = url
      if data['content_urls'] && data['content_urls']['desktop'] && data['content_urls']['desktop']['page']
        canonical_url = data['content_urls']['desktop']['page']
      end

      {
        'title' => data['title'] || data['displaytitle'],
        'description' => data['extract'] || data['description'] || '',
        'image' => image_url || '',
        'site_name' => 'Wikipedia',
        'canonical_url' => canonical_url,
        'fetched_at' => Time.now.iso8601
      }
    rescue StandardError => e
      Jekyll.logger.warn "RecommendationFetcher:", "Wikipedia API failed for #{url}: #{e.message}, falling back to OpenGraph"
      fetch_opengraph_metadata(url)
    end

    def fetch_opengraph_metadata(url)
      html = http_get(url)
      return nil if html.nil? || html.empty?

      title = extract_meta(html, 'og:title') || extract_tag(html, 'title')
      description = extract_meta(html, 'og:description') || extract_meta(html, 'description', name_attr: 'name')
      image = extract_meta(html, 'og:image')
      site_name = extract_meta(html, 'og:site_name') || site_name_from_url(url)

      # Clean HTML tags and unescape entities
      title = clean_text(title) if title
      description = clean_text(description) if description

      {
        'title' => title || default_title_from_url(url),
        'description' => description || '',
        'image' => image || '',
        'site_name' => site_name,
        'canonical_url' => url,
        'fetched_at' => Time.now.iso8601
      }
    end

    def http_get(url_str, limit = 5)
      return nil if limit <= 0

      uri = URI.parse(url_str)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = 5
      http.read_timeout = 5

      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = USER_AGENT
      request['Accept'] = 'text/html,application/json,application/xhtml+xml,*/*'

      response = http.request(request)
      case response
      when Net::HTTPSuccess
        charset = response.type_params['charset'] || 'UTF-8'
        response.body.dup.force_encoding(charset).encode(Encoding::UTF_8)
      when Net::HTTPRedirection
        redirect_url = response['location']
        redirect_url = URI.join(url_str, redirect_url).to_s unless redirect_url.start_with?('http')
        http_get(redirect_url, limit - 1)
      else
        nil
      end
    rescue StandardError => e
      Jekyll.logger.warn "RecommendationFetcher:", "HTTP error for #{url_str}: #{e.message}"
      nil
    end

    def extract_meta(html, property, name_attr: 'property')
      regex = /<meta\s+[^>]*#{name_attr}=["']#{Regexp.escape(property)}["']\s+[^>]*content=["']([^"']+)["']/i
      match = html.match(regex)
      return match[1] if match

      # Alternative ordering: content before property/name
      regex_alt = /<meta\s+[^>]*content=["']([^"']+)["']\s+[^>]*#{name_attr}=["']#{Regexp.escape(property)}["']/i
      match_alt = html.match(regex_alt)
      match_alt ? match_alt[1] : nil
    end

    def extract_tag(html, tag)
      match = html.match(/<#{tag}[^>]*>(.*?)<\/#{tag}>/im)
      match ? match[1] : nil
    end

    def clean_text(text)
      return '' if text.nil?
      clean = text.gsub(/<\/?[^>]+>/, '')
      CGI.unescapeHTML(clean).strip
    end

    def default_title_from_url(url)
      uri = URI.parse(url)
      path = uri.path.split('/').reject(&:empty?).last || uri.host
      path.tr('_', ' ').sub(/\.[^.]+\z/, '')
    rescue StandardError
      url
    end

    def site_name_from_url(url)
      uri = URI.parse(url)
      host = uri.host.to_s.downcase
      if host.include?('spotify.com')
        'Spotify'
      elsif host.include?('youtube.com') || host.include?('youtu.be')
        'YouTube'
      elsif host.include?('apple.com')
        'Apple Music'
      elsif host.include?('wikipedia.org')
        'Wikipedia'
      elsif host.include?('books.google.')
        'Google Books'
      else
        host.sub(/\Awww\./, '').split('.').first.capitalize
      end
    rescue StandardError
      'Web'
    end
  end
end

