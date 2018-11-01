locals {
  macbot_labels = {
    app = "macbot"
  }

  imaged_labels = {
    app = "imaged"
  }
}

locals {
  extra_image_builder_secrets = {
    aws_access_key = "phony-key"
    aws_secret_key = "phony-secret"
  }
}

resource "kubernetes_secret" "image_builder" {
  metadata {
    name = "image-builder"
  }

  data = "${merge(var.image_builder_secrets, local.extra_image_builder_secrets)}"
}

locals {
  secrets_name = "${kubernetes_secret.image_builder.metadata.0.name}"
}

resource "kubernetes_deployment" "macbot" {
  metadata {
    name   = "macbot"
    labels = "${local.macbot_labels}"
  }

  spec {
    selector {
      match_labels = "${local.macbot_labels}"
    }

    template {
      metadata {
        labels = "${local.macbot_labels}"
      }

      spec {
        container {
          image = "travisci/macbot:latest"
          name  = "macbot"

          env {
            name  = "MACBOT_IMAGED_URL"
            value = "http://imaged:8080"
          }

          env {
            name = "SLACK_API_TOKEN"

            value_from {
              secret_key_ref {
                name = "${local.secrets_name}"
                key  = "slack_api_token"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "imaged" {
  metadata {
    name   = "imaged"
    labels = "${local.imaged_labels}"
  }

  spec {
    selector {
      match_labels = "${local.imaged_labels}"
    }

    template {
      metadata {
        labels = "${local.imaged_labels}"
      }

      spec {
        container {
          image = "travisci/imaged:latest"
          name  = "imaged"

          env {
            name  = "IMAGED_TEMPLATES_URL"
            value = "https://github.com/travis-ci/packer-templates-mac.git"
          }

          env {
            name  = "IMAGED_RECORD_BUCKET"
            value = "phony-bucket"
          }

          env {
            name  = "AWS_REGION"
            value = "us-east-1"
          }

          env {
            name = "AWS_ACCESS_KEY"

            value_from {
              secret_key_ref {
                name = "${local.secrets_name}"
                key  = "aws_access_key"
              }
            }
          }

          env {
            name = "AWS_SECRET_KEY"

            value_from {
              secret_key_ref {
                name = "${local.secrets_name}"
                key  = "aws_secret_key"
              }
            }
          }

          env {
            name = "IMAGED_DATABASE_URL"

            value_from {
              secret_key_ref {
                name = "${local.secrets_name}"
                key  = "imaged_database_url"
              }
            }
          }
        }
      }
    }
  }
}

# macbot needs a service to be able to reach imaged
resource "kubernetes_service" "imaged" {
  metadata {
    name   = "imaged"
    labels = "${local.imaged_labels}"
  }

  spec {
    selector = "${local.imaged_labels}"

    port {
      port = 8080
    }
  }
}
