# delaunay 的 test case ( @makechart/viewer 的 mctest )
names = <[Forrest Nemo Fly Blood Hell Rider Patient Scissorhands Empire Elizabeth]>
# 每份資料用自己的種子, 跟產生的先後順序無關
mk = (n, seed = n) ->
  rnd = mctest.random seed
  raw: [0 til n].map -> {x: rnd!, y: rnd!, name: names[Math.floor(rnd! * names.length)]}
  binding: {x: {key: \x}, y: {key: \y}, name: {key: \name}}

mctest.suite do
  size: [480, 360]
  data:
    many: mk 40
    few: mk 6
  cases:
    * name: "many", data: \many
    * name: "few", data: \few
    * name: "update", data: \few, steps: (c) -> d = mk 12, 3; c.set-raw d.raw, d.binding
