let
  sphoono = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsLDpds7sJGuczBvZEIkqEBwjdk22MbiML/WYzHwzkT Personal Key";
in {
  "secrets/testing_age_key.age".publicKeys = [sphoono];
  "secrets/ghcr_pat.age".publicKeys = [sphoono];
}
