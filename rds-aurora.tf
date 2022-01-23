data "aws_rds_engine_version" "aurora-mysql" {
  engine = "aurora-mysql"
}

locals {
  pg = {
    cluster = {
      # pg_family = "aurora-mysql5.7" # バージョンを固定する場合
      pg_family = data.aws_rds_engine_version.aurora-mysql.parameter_group_family # 最新バージョンの取得(新規作成時)

      cluster_parameters = {
        time_zone = {
          value        = "Asia/Tokyo"
          apply_method = "immediate"
        }
        character_set_server = {
          value        = "utf8"
          apply_method = "immediate"
        }
        server_audit_logging = {
          value        = "1"
          apply_method = "immediate"
        }
        server_audit_events = {
          value        = "CONNECT,QUERY,TABLE"
          apply_method = "immediate"
        }
      }
    }

    db = {
      # DBインスタンスのパラメータグループはRoleごとに作成
      # cluster = aws_rds_cluster.this.name
      db_parameters = {
      #   slow_query_log = {
      #     value        = "1"
      #     apply_method = "immediate"
      #   }
      #   log_output = {
      #     value        = "FILE"
      #     apply_method = "immediate"
      #   }
      #   long_query_time = {
      #     value        = "10"
      #     apply_method = "immediate"
      #   }
      }
    }
  }
}

## Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${var.system_name}-sg"
  subnet_ids = [for v in aws_subnet.this : v.id if v.tags.Role == "private"]
}

## Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "this" {

  name        = "${var.system_name}-pg"
  description = "${var.system_name}-pg"
  family      = local.pg.cluster.pg_family

  dynamic "parameter" {
    for_each = local.pg.cluster.cluster_parameters

    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, null)
    }
  }
}

## DB Parameter Group
resource "aws_db_parameter_group" "this" {
  name        = "${var.system_name}-pg"
  description = "${var.system_name}-pg"
  family      = aws_rds_cluster_parameter_group.this.family

  dynamic "parameter" {
    for_each = local.pg.db.db_parameters

    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, null)
    }
  }
}

# ## Serverless Aurora
resource "aws_rds_cluster" "this" {
  cluster_identifier              = "${var.system_name}-rds-001"
  engine_mode                     = "serverless"
  engine                          = "aurora-mysql"
  engine_version                  = "5.7"
  database_name                   = "redmine"
  master_username                 = var.db_user
  master_password                 = var.db_password
  db_subnet_group_name            = aws_db_subnet_group.this.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.this.id]

  scaling_configuration {
    auto_pause               = true
    seconds_until_auto_pause = 300
    max_capacity             = 16
    min_capacity             = 1
    timeout_action           = "ForceApplyCapacityChange"
  }
}
