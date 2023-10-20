# Scenario 1: Sample Lab Report
Generated output for the provided sample can be found
[here](sample-output/SampleLabListTransformed.csv)

Please let me know if you have any questions, or need any of this code explained. It's possible that
I've gone over the top with the error handling, which has unnecessarily complicated the code. I'm
more than happy to walk you through it if haskell/FP is completely foreign to you.

## Building and Running
Building from source is done via `nix`, which is over the top, but briefly:
```bash
nix-build -A lab-report.components.exes.lab-report
```

Will leave an output binary at `./result/bin/lab-report`

The binary reads over stdin and prints to stdout, so to run with the sample data contained in the
repository, you could run:
```bash
./result/bin/lab-report < ../resources/SampleLabList.csv > sample-output/SampleLabListTransformed.csv
```

## Error handling and reporting
Without providing a running binary, and assuming that Nix is too hard to setup, testing the error
handling code will likely be difficult. If you like I can email/commit some examples.
