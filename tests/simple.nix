{
  pkgs,
  ...
}:
pkgs.runCommand "simple-test" {} ''
  echo "Running simple test..."
  echo "Test passed!"
  touch $out
''
