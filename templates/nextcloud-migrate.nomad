{% from '_lib.hcl' import group_disk, task_logs, continuous_reschedule, promtail_task -%}

job "nextcloud-migrate" {
  datacenters = ["dc1"]
  type = "batch"
  priority = 45

  group "migrate" {
    ${ group_disk() }

    reschedule {
      attempts       = 6
      interval       = "1h"
      delay          = "40s"
      delay_function = "exponential"
      max_delay      = "300s"
      unlimited      = false
    }

    task "script" {
      leader = true

      constraint {
        attribute = "{% raw %}${meta.liquid_volumes}{% endraw %}"
        operator = "is_set"
      }
      constraint {
        attribute = "{% raw %}${meta.liquid_collections}{% endraw %}"
        operator = "is_set"
      }

      ${ task_logs() }

      driver = "docker"
      config {
        image = "${config.image('liquid-nextcloud')}"
        volumes = [
          "{% raw %}${meta.liquid_volumes}{% endraw %}/nextcloud/nextcloud:/var/www/html",
          "{% raw %}${meta.liquid_collections}{% endraw %}/uploads/data:/var/www/html/data/uploads/files",
        ]
        args = ["sudo", "-Eu", "www-data", "bash", "/local/setup.sh"]
        labels {
          liquid_task = "nextcloud-migrate"
        }
      }
      template {
        data = <<EOF
# Auto-generated by nextcloud migrate script
# Timestamp: ${config.timestamp}
{% include 'nextcloud-setup.sh' %}
        EOF
        destination = "local/setup.sh"
      }
      template {
        data = <<-EOF
        HTTP_PROTO = "${config.liquid_http_protocol}"
        NEXTCLOUD_HOST = "nextcloud.{{ key "liquid_domain" }}"
        NEXTCLOUD_ADMIN_USER = "admin"
        {{- with secret "liquid/nextcloud/nextcloud.admin" }}
          NEXTCLOUD_ADMIN_PASSWORD = {{.Data.secret_key | toJSON }}
        {{- end }}
        {{- range service "nextcloud-maria" }}
          MYSQL_HOST = "{{.Address}}:{{.Port}}"
        {{- end }}
        MYSQL_DB = "nextcloud"
        MYSQL_USER = "nextcloud"
        {{- with secret "liquid/nextcloud/nextcloud.maria" }}
          MYSQL_PASSWORD = {{.Data.secret_key | toJSON }}
        {{- end }}
        {{- with secret "liquid/nextcloud/nextcloud.uploads" }}
          UPLOADS_USER_PASSWORD = {{.Data.secret_key | toJSON }}
        {{- end }}
        TIMESTAMP = "${config.timestamp}"
        EOF
        destination = "local/nextcloud-migrate.env"
        env = true
      }
      resources {
        memory = 700
        cpu = 200
      }
    }

    ${ promtail_task() }
  }
}
