terraform {
  backend "remote" {
    hostname     = "terraform.lpcloud.io"
    organization = "LivePerson"

    workspaces {
      name = "tf-lpgprj-b2b-q-dbeng-us-1"
    }
  }
}
