{%- from "letsencrypt/map.jinja" import client with context %}

{%- if client.enabled %}

letsencrypt-packages:
  pkg.installed:
  - names: {{ client.source.pkgs }}

letsencrypt-config:
  file.managed:
    - name: /etc/letsencrypt/cli.ini
    - makedirs: true
    - contents_pillar: letsencrypt:client:config

letsencrypt-client-git:
  git.latest:
    - name: https://github.com/letsencrypt/letsencrypt
    - target: {{ client.cli_install_dir }}

{% for setname, domainlist in client.domainset.items() %}
create-initial-cert-{{ setname }}-{{ domainlist[0] }}:
  cmd.run:
    - unless: ls /etc/letsencrypt/live/{{ domainlist[0] }}
    - name: {{ client.cli_install_dir }}/letsencrypt-auto -d {{ domainlist|join(' -d ') }} certonly
    - require:
      - file: letsencrypt-config

letsencrypt-crontab-{{ setname }}-{{ domainlist[0] }}:
  cron.present:
    - name: {{ client.cli_install_dir }}/letsencrypt-auto -d {{ domainlist|join(' -d ') }} certonly
    - month: '*/2'
    - minute: random
    - hour: random
    - daymonth: random
    - identifier: letsencrypt-{{ setname }}-{{ domainlist[0] }}
    - require:
      - cmd: create-initial-cert-{{ setname }}-{{ domainlist[0] }}

compile-cert-for-haproxy-{{ setname }}-{{ domainlist[0] }}:
  cmd.run:
    - only_if: ls /etc/letsencrypt/live/{{ domainlist[0] }}
    - name: cat /etc/letsencrypt/live/{{ domainlist[0] }}/fullchain.pem /etc/letsencrypt/live/{{ domainlist[0] }}/privkey.pem > /srv/salt/env/base/_files/{{ domainlist[0] }}.crt

{% endfor %}

{%- endif %}
