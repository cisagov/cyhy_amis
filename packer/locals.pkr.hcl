locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}
