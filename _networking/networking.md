---
layout: default
title: Networking Book
permalink: /networking/
---

# Networking Guide

Choose your language below to begin reading.

## 🇬🇧 English Chapters
<ul>
  {% assign en_chapters = site.networking | where: "lang", "en" | sort: 'order' %}
  {% for chapter in en_chapters %}
    <li><a href="{{ chapter.url }}">{{ chapter.title }}</a></li>
  {% endfor %}
</ul>

<div dir="rtl">
  <h2>🇮🇷 فصل‌های فارسی</h2>
  <ul>
    {% assign fa_chapters = site.networking | where: "lang", "fa" | sort: 'order' %}
    {% for chapter in fa_chapters %}
      <li><a href="{{ chapter.url }}">{{ chapter.title }}</a></li>
    {% endfor %}
  </ul>
</div>
