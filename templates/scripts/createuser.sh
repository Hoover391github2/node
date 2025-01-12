#!/bin/sh
apt-get install pip
pip install requests
set -ex
liquid_domain="${liquid_domain}"
echo "Creating user {% raw %}'${NOMAD_META_USERNAME}'{% endraw %} for all enabled apps."

{% if config.is_app_enabled('hoover') %}
echo "Creating Hoover user..."
${exec_command('hoover:search', './manage.py', 'createuser', '${NOMAD_META_USERNAME}')}
{% endif %}


{% if config.is_app_enabled('rocketchat') %}
echo "Creating Rocketchat user..."
python local/create_rocket_user.py {% raw %}${NOMAD_META_USERNAME}{% endraw %}
{% endif %}

{% if config.is_app_enabled('codimd') %}
echo "Creating CodiMD user..."
${exec_command('codimd:codimd', '/codimd/bin/manage_users', '--profileid=${NOMAD_META_USERNAME}', '--domain="$liquid_domain"')}
{% endif %}
