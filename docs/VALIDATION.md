# Publication review

The public source was assembled from an explicit file list, preserving the
original recovery kit separately. No original restore logs, runtime/pairing
records, cache, firmware payload, compiled binaries, downloaded dependencies,
third-party source trees, or copied web assets were added to Git.

Checks performed for publication:

- Gitleaks 8.30.1 scanned the staged publication with no findings.
- Additional checks found no private-key headers, credential-bearing URLs,
  personal filesystem paths, email addresses, or device identifiers extracted
  from the original restore logs in the new publication files.
- Git ignore rules were checked against representative pairing, firmware,
  signing-ticket, key, environment, log, and build paths.
- ShellCheck passed for all shell helpers; Python syntax checks passed.
- Downloader checks passed for download completion, reuse of an existing image,
  checksum rejection, and stale resume metadata without a partial image.
- All eight upstream projects were fetched at the recorded commits and built
  successfully using the recorded Ubuntu package versions.
- The full original IPSW passed SHA-256 verification. The rebuilt tools started
  with their local libraries, and the IPSW manifest and idevicerestore metadata
  checks passed without contacting or restoring a device.

These checks do not guarantee the absence of every possible form of sensitive
information. Git ignores can be overridden; inspect changes before publishing
future diagnostic output. The original repository's initial LICENSE commit
and its existing author metadata were retained. New publication commits use a
GitHub noreply address.

The original successful physical restore is described in the README. Publication
validation does not perform another erase restore or check backup contents.
