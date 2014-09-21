{% set servers = salt["mine.get"]("roles:postgresql", "minealiases.psf_internal", expr_form="grain") %}

postgresql:
  pkg.installed:
    - pkgs:
      - postgresql-client-9.3
      - pgbouncer
      - stunnel4


/etc/stunnel/stunnel.conf:
  file.managed:
    - source: salt://postgresql/configs/stunnel.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 640
    - require:
      - pkg: postgresql


/etc/default/stunnel4:
  file.managed:
    - source: salt://postgresql/configs/stunnel-default
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: postgresql


{% for user in salt["pillar.get"]("postgresql-users") %}
/etc/ssl/certs/{{ user }}.pem:
  file.managed:
    - contents_pillar: postgresql-users:{{ user }}:crt
    - user: root
    - group: ssl-cert
    - mode: 640

/etc/ssl/private/{{ user }}.key:
  file.managed:
    - contents_pillar: postgresql-users:{{ user }}:key
    - user: root
    - group: ssl-cert
    - mode: 640
{% endfor %}


{% for server in servers %}
/var/run/stunnel4/{{ server }}:
  file.directory:
    - user: root
    - group: root
    - mode: 750
    - require:
      - pkg: postgresql
{% endfor %}


stunnel4:
  service.running:
    - enable: True
    - watch:
      - file: /etc/stunnel/stunnel.conf
    - require:
      - pkg: postgresql
      - file: /etc/stunnel/stunnel.conf
      {% for server in servers %}
      - file: /var/run/stunnel4/{{ server }}
      {% endfor %}