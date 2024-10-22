module Jekyll
    class PostReader
      def self.get_raw_content(post)
        # Reads the raw content directly from the file
        File.read(post.path)
      end
    end

    Hooks.register :posts, :pre_render do |post|
      # Expose raw content as a new variable
      post.data['raw_content'] = PostReader.get_raw_content(post)
    end
  end
