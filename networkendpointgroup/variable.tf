variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "cloudrun_service" {
  type = string
}

variable "regions" {
  type = list(string)
}
