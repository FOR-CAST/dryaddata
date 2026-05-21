# print.dryad_search summarizes results

    Code
      print(res)
    Message
      Dryad datasets: 2 of 2
      1: Test dataset 1
      doi:10.5061/dryad.test1 — published: 2026-01-01 • authors: A B1
      2: Test dataset 2
      doi:10.5061/dryad.test2 — published: 2026-01-01 • authors: A B2
    Output
      
    Message
      i Get one with `dryad_dataset("<identifier>")`.
      i List its files with `dryad_version_files(<version_id>)`.
      i Download with `dryad_download_dataset("<identifier>")`.
      Inspect with `$data` (data.frame), `$records` (raw list), or `$metadata`.

# print.dryad_dataset shows headline metadata + next steps

    Code
      print(ds)
    Message
      Dryad dataset: Example dataset
    Output
        Identifier  doi:10.5061/dryad.j1fd7
        Authors     Jane Doe
        Version     v1
        Published   2026-01-01
      
    Message
      Abstract: A sandbox dataset used in tests.
    Output
      
    Message
      i List versions: `dryad_dataset_versions("doi:10.5061/dryad.j1fd7")`
      i Download: `dryad_download_dataset("doi:10.5061/dryad.j1fd7")`
      i Inspect nested fields with `$authors`, `` $`_links` ``, etc.

# print.dryad_version_files lists files with ids

    Code
      print(fl)
    Message
      Dryad version files: 2 of 2
      1: data.csv
      id: 94868 | size: 123 B | type: text/csv
      2: readme.txt
      id: 94869 | size: 45 B | type: text/plain
    Output
      
    Message
      i Download with `dryad_download_file(<id>)`.
      Inspect with `$data` (data.frame), `$records` (raw list), or `$metadata`.

# print.dryad_file shows id/size/type

    Code
      print(f)
    Message
      Dryad file: example.csv
    Output
        Id      123456
        Size    11 B
        Type    text/csv
        Status  created
        Digest  md5 deadbeef
      
    Message
      i Download: `dryad_download_file(123456)`

