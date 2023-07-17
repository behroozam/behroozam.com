---
layout: page
title:  دسته‌بندی ها
permalink: /categories/
---
<div>
{% for cat in site.categories %}
  <div>
    {% capture cat_name %}{{ cat | first }}{% endcapture %}
    <h5>{{ cat_name }}</h5>
    {% for post in site.categories[cat_name] %}
    <article>
      <a href="{{ site.url }}{{ post.url }}">{{post.title}}</a>
    </article>
    {% endfor %}
  </div>
{% endfor %}
</div>
