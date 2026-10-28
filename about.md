---
layout: default
title: Behrouz Hassanbeygi | About
permalink: /about/
description: A platform engineer's little corner of the shell. Linux, Kubernetes, infrastructure, and a few things in between.
---

<div class="about-terminal-page">
  <header class="post-nav post-nav--top">{%- include back_link.html -%}</header>

  <section class="terminal-window" aria-label="Interactive terminal profile">
    <div class="terminal-titlebar">
      <div class="terminal-lights" aria-hidden="true"><i></i><i></i><i></i></div>
      <span class="terminal-title">behrooz@platform: ~</span>
      <span class="terminal-titlebar__right">bash <span>▾</span></span>
    </div>

    <div class="terminal-workspace">
      <div class="terminal-main">
        <div class="terminal-output" id="terminal-output" role="log" aria-live="polite" aria-relevant="additions">
          <div class="terminal-line terminal-line--muted">Linux behrooz-workstation 6.x.x x86_64</div>
          <div class="terminal-line terminal-line--muted">A human-maintained platform. No warranty, many opinions.</div>
          <div class="terminal-spacer"></div>
          <div class="terminal-welcome">
            <p class="terminal-line"><span class="terminal-prompt">$</span> ./hello-world</p>
            <p class="terminal-line terminal-line--bright">Hey, I'm Behrouz <span class="terminal-cursor" aria-hidden="true"></span></p>
            <p class="terminal-line">Senior DevOps / Platform Engineer, Linux enthusiast,</p>
            <p class="terminal-line">and professional asker of <em>"what does the packet see?"</em></p>
            <p class="terminal-line terminal-line--accent">Currently building Kubernetes platforms in Sydney.</p>
            <p class="terminal-line terminal-line--muted">Type <code>help</code> to explore. No sudo required.</p>
          </div>
        </div>

        <form class="terminal-input-row" id="terminal-form" autocomplete="off">
          <label class="terminal-prompt" for="terminal-input">behrooz@platform:~$</label>
          <input id="terminal-input" name="command" type="text" spellcheck="false" autocapitalize="off" aria-label="Enter a terminal command" autofocus />
          <span class="terminal-cursor" aria-hidden="true"></span>
        </form>

        <div class="terminal-shortcuts" aria-label="Try a command">
          <span>TRY</span>
          <button type="button" data-terminal-command="neofetch">neofetch</button>
          <button type="button" data-terminal-command="stack">stack</button>
          <button type="button" data-terminal-command="experience">experience</button>
          <button type="button" data-terminal-command="contact">contact</button>
        </div>
      </div>

      <aside class="terminal-aside" aria-label="System profile">
        <div class="terminal-aside__top"><span>USER PROFILE</span><span class="terminal-online">● ONLINE</span></div>
        <img class="terminal-avatar" src="{{ '/assets/images/behroozam.jpg' | relative_url }}" alt="Behrouz Hassanbeygi" />
        <h1>Behrouz<br />Hassanbeygi</h1>
        <p class="terminal-aside__role">Senior DevOps / Platform Engineer</p>
        <dl class="terminal-facts">
          <div><dt>base</dt><dd>Sydney, Australia</dd></div>
          <div><dt>uptime</dt><dd>9+ years in infra</dd></div>
          <div><dt>specialty</dt><dd>Kubernetes &amp; Linux</dd></div>
          <div><dt>side quest</dt><dd>SUSE Certified Instructor</dd></div>
        </dl>
        <div class="terminal-socials">
          <a href="https://github.com/behroozam" target="_blank" rel="noopener noreferrer">GitHub <span>↗</span></a>
          <a href="https://www.linkedin.com/in/behroozam/" target="_blank" rel="noopener noreferrer">LinkedIn <span>↗</span></a>
          <a href="https://medium.com/@behroozam" target="_blank" rel="noopener noreferrer">Writing <span>↗</span></a>
        </div>
      </aside>
    </div>
    <div class="terminal-statusbar"><span><i></i> shell ready</span><span>UTF-8</span><span>SYDNEY / AEDT</span></div>
  </section>

  <p class="terminal-footnote">Built from curiosity, coffee, and a suspicious number of <code>man</code> pages.</p>
</div>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    var form = document.getElementById('terminal-form');
    var input = document.getElementById('terminal-input');
    var output = document.getElementById('terminal-output');
    var shortcuts = document.querySelectorAll('[data-terminal-command]');
    var history = [];
    var historyIndex = 0;

    if (!form || !input || !output) return;

    var responses = {
      help: '<p>Available commands:</p><ul><li><code>whoami</code> — the short version</li><li><code>neofetch</code> — system profile</li><li><code>stack</code> — favorite tools</li><li><code>experience</code> — career, without the PDF</li><li><code>certs</code> — teaching and certifications</li><li><code>contact</code> — open a channel</li><li><code>clear</code> — clean the terminal</li></ul>',
      whoami: '<p><strong>Behrouz Hassanbeygi</strong> — Senior DevOps / Platform Engineer in Sydney.</p><p>I build platforms that let teams ship software without having to become infrastructure archaeologists.</p><p>Most at home around Linux, Kubernetes, networking, automation, and the occasional stubborn production incident.</p>',
      neofetch: '<pre class="terminal-fetch">  .--.       behrooz@platform\n |o_o |      -----------------\n |:_/ |      OS: Linux (by choice)\n//   \\ \\     Role: Platform Engineer\n(|     | )    Runtime: Kubernetes\n/\\_   _/ \\    Shell: Bash + curiosity\n\\___)=(___/   Location: Sydney</pre>',
      stack: '<p><strong>Things I reach for:</strong></p><ul><li>Orchestration: Kubernetes, RKE2, Rancher, OpenShift</li><li>Cloud &amp; IaC: Azure, AWS, GCP, Terraform, Ansible</li><li>Networking: Cilium, Gateway API, DNS, TLS, load balancing</li><li>Delivery: Argo CD, Helm, Kustomize, GitHub Actions</li><li>Daily drivers: Linux, Go, Python, Bash</li><li>Observability &amp; storage: Prometheus, Grafana, Ceph</li></ul>',
      experience: '<p><strong>Recent commits to the career timeline:</strong></p><ul><li>2026–now · Yunex Traffic — multi-region, on-prem Kubernetes with Rancher and RKE2</li><li>2025 · Darumatic — EKS migration, Terraform, learning platforms, SUSE instructor</li><li>2023–2025 · Nord Pool — Azure Landing Zone, Terraform modules, GitOps</li><li>2022–2023 · Smartly.io — Go load balancer, 2,000+ bare-metal servers</li><li>2021 · Hasty — multi-cloud, Linkerd, ARM build pipelines</li><li>2017–2021 · Snapp!, Alibaba Travels, Fanap+ / Arna — cloud and DevOps</li></ul>',
      certs: '<p><strong>SUSE Certified Instructor.</strong></p><p>Authorized to teach official courses in Kubernetes Administration, RKE2 Deployment, and Rancher Prime operations. Also certified in SUSE Linux Enterprise Server 15.</p>',
      contact: '<p>Have an interesting platform problem, a Kubernetes question, or a good Linux story?</p><p><a href="mailto:b.hasanbg@gmail.com">b.hasanbg@gmail.com ↗</a></p><p><a href="https://www.linkedin.com/in/behroozam/" target="_blank" rel="noopener noreferrer">LinkedIn ↗</a> · <a href="https://github.com/behroozam" target="_blank" rel="noopener noreferrer">GitHub ↗</a></p>',
      hire: '<p><span class="terminal-ok">Permission granted.</span> Let’s talk about the work: <a href="mailto:b.hasanbg@gmail.com">b.hasanbg@gmail.com ↗</a></p>',
      uname: '<p>Linux behrooz-workstation 6.x.x #1 SMP x86_64 GNU/Linux</p>'
    };

    function appendCommand(command) {
      var commandLine = document.createElement('p');
      commandLine.className = 'terminal-line terminal-command-echo';
      commandLine.textContent = 'behrooz@platform:~$ ' + command;
      output.appendChild(commandLine);

      if (command === 'clear') {
        output.innerHTML = '';
        return;
      }

      var key = command.toLowerCase();
      var html = responses[key];
      if (key === 'sudo hire-me' || key === 'hire-me') html = responses.hire;
      if (key === 'uname -a') html = responses.uname;

      var result = document.createElement('div');
      result.className = html ? 'terminal-result' : 'terminal-result terminal-result--error';
      result.innerHTML = html || '<p>bash: ' + escapeText(command) + ': command not found. Try <code>help</code>.</p>';
      output.appendChild(result);
      output.scrollTop = output.scrollHeight;
    }

    function escapeText(text) {
      return text.replace(/[&<>"']/g, function (character) {
        return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[character];
      });
    }

    form.addEventListener('submit', function (event) {
      event.preventDefault();
      var command = input.value.trim();
      if (!command) return;
      history.push(command);
      historyIndex = history.length;
      appendCommand(command);
      input.value = '';
      input.focus();
    });

    input.addEventListener('keydown', function (event) {
      if (event.key === 'ArrowUp') {
        event.preventDefault();
        historyIndex = Math.max(0, historyIndex - 1);
        input.value = history[historyIndex] || '';
      } else if (event.key === 'ArrowDown') {
        event.preventDefault();
        historyIndex = Math.min(history.length, historyIndex + 1);
        input.value = history[historyIndex] || '';
      }
    });

    shortcuts.forEach(function (button) {
      button.addEventListener('click', function () {
        var command = button.getAttribute('data-terminal-command');
        input.value = command;
        form.requestSubmit();
        input.focus();
      });
    });
  });
</script>
