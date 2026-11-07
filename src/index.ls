module.exports =
  pkg:
    name: 'delaunay', version: '0.0.1'
    # lite: 不帶 d3 的 base ( 見 @plotdb/chart utils )
    extend: {name: "@makechart/base", path: "lite/index.html"}
    # d3-delaunay 的 UMD 已內含 delaunator, 不需要 d3 core
    dependencies: [
    * name: \d3-delaunay, version: "6.0.4", path: "dist/d3-delaunay.min.js", async: false
    ]

  init: ({root, context, pubsub}) ->
    pubsub.fire \init, mod: mod {context}

mod = ({context}) ->
  {d3,chart} = context
  {scale: Scale, anim: {join}} = chart.utils
  svgns = "http://www.w3.org/2000/svg"
  # 同 d3.extent: 略過 null / NaN
  extent = (list) ->
    vs = list.filter -> it? and +it >= +it
    if vs.length => [vs.reduce(((a,b) -> if b < a => b else a)), vs.reduce(((a,b) -> if b > a => b else a))]
    else [undefined, undefined]
  # 同 d3.polygonArea / d3.polygonCentroid ( 移植自 d3-polygon, ISC )
  polygon-area = (p) ->
    [n, b, area] = [p.length, p[p.length - 1], 0]
    for i from 0 til n
      a = b
      b = p[i]
      area += a.1 * b.0 - a.0 * b.1
    area / 2
  polygon-centroid = (p) ->
    [n, x, y, k, b] = [p.length, 0, 0, 0, p[p.length - 1]]
    for i from 0 til n
      a = b
      b = p[i]
      k += c = a.0 * b.1 - b.0 * a.1
      x += (a.0 + b.0) * c
      y += (a.1 + b.1) * c
    k *= 3
    [x / k, y / k]
  names = [
    "The Glenn Miller Story",
    "The Fifth Element",
    "Forrest Gump",
    "Finding Nemo",
    "The Fly",
    "First Blood",
    "You Can't Take It with You",
    "Man of the Year",
    "From Hell",
    "The Easy Rider",
    "The English Patient",
    "The Extra-Terrestial",
    "Edward Scissorhands",
    "Empire of the Sun",
    "Encounters of the Third Kind",
    "Elizabeth: The Golden Age",
  ]
  sample: ->
    raw: [0 to 100].map (val) ~> 
      ret = x: Math.random!, y: Math.random!, name: names[Math.floor(Math.random! * names.length)]
      ret
    binding:
      x: {key: \x}
      y: {key: \y}
      name: {key: \name}
  config: {}
  dimension:
    x: {type: \R, name: "x axis"}
    y: {type: \R, name: "y axis"}
    radius: {type: \R, name: "radius"}
    category: {type: \CN, name: "category"}
    name: {type: \N, name: "name"}
  init: ->
    @tint = tint = new chart.utils.tint!
    <[view yaxis xaxis]>.map ~> @{}g[it] = @layout.get-group(it)
    @path = @svg.appendChild document.createElementNS(svgns, \path)

  parse: ->

  resize: ->
    [w,h] = [@box.width, @box.height]
    @extent =
      x: extent @data.map -> it.x
      y: extent @data.map -> it.y
    box = @layout.get-box \view
    @scale =
      x: Scale.linear!domain @extent.x .range [0, box.width]
      y: Scale.linear!domain @extent.y .range [0, box.height]
    @pts = @data.map (d) ~> [@scale.x(d.x), @scale.y(d.y)]
    @delaunay = d3.Delaunay.from @pts
    @voronoi = @delaunay.voronoi [0, 0, box.width, box.height]
    @cells = @pts
      .map (point,i) ~>
        [x,y] = point
        polygon = @voronoi.cellPolygon i
        [cx,cy] = centroid = polygon-centroid polygon
        area = -polygon-area polygon
        angle = (Math.round(Math.atan2(cy - y, cx - x) / Math.PI * 2) + 4) % 4
        {point, polygon, centroid, area, angle}

  render: ->
    {scale} = @
    pos = (d) -> [(if d.nb => d.nb.x else scale.x(d.x)), (if d.nb => d.nb.y else scale.y(d.y))]
    cj = join root: @g.view, tag: \circle, cls: \data, data: @data
    cj.exit.map -> it.remove!
    cj.enter.map (n) ->
      d = n.__data__
      n.setAttribute \cx, scale.x d.x
      n.setAttribute \cy, scale.y d.y
      n.setAttribute \r, 3
      n.setAttribute \fill, \#000
    tj = join root: @g.view, tag: \text, data: @data
    tj.exit.map -> it.remove!
    tj.enter.map (n) ->
      d = n.__data__
      n.textContent = d.name
      [x, y] = pos d
      n.setAttribute \x, x
      n.setAttribute \y, y
      n.setAttribute \text-anchor, \middle
      n.setAttribute \dominant-baseline, \middle
    tj.nodes.map (n) ->
      d = n.__data__
      n.setAttribute \x, if d.nb => d.nb.x else scale.x(d.x)
      n.setAttribute \y, if d.nb => d.nb.y else scale.y(d.y) - 20
      n.setAttribute \opacity, if d.nb => (if d.nb.show => 1 else 0) else 1
    @path.setAttribute \d, @voronoi.render!
    @path.setAttribute \stroke, \#000
    if (t = @g.view.getAttribute(\transform))? => @path.setAttribute \transform, t
    else @path.removeAttribute \transform
  tick: ->
    scale = @scale
    Array.from(@g.view.querySelectorAll ':scope > text').map -> it.__data__.box = it.getBoundingClientRect!
    rbox = @layout.get-box \view
    for i from 0 til @data.length =>
      d = @data[i].box
      if !@data[i].nb => @data[i].nb = x: scale.x(@data[i].x), y: scale.y(@data[i].y) - 20
      @data[i].nb <<< width: d.width, height: d.height, show: true
    for r from 20 til 200 by 20
      for i from 0 til @data.length =>
        for j from 0 til i =>
          [a,b] = [@data[i].nb, @data[j].nb]
          if ((a.x >= b.x and a.x <= b.x + b.width) or (a.x + a.width >= b.x and a.x + a.width <= b.x + b.width)) and
             ((a.y >= b.y and a.y <= b.y + b.height) or (a.y + a.height >= b.y and a.y + a.height <= b.y + b.height)) =>
            d = Math.random! * Math.PI * 2
            data = @data[i]
            data.nb <<< {x: scale.x(data.x) + (Math.cos(d) * r), y: scale.y(data.y) + (Math.sin(d) * r)}
    for i from 0 til @data.length =>
      for j from 0 til i =>
        [a,b] = [@data[i].nb, @data[j].nb]
        if ((a.x >= b.x and a.x <= b.x + b.width) or (a.x + a.width >= b.x and a.x + a.width <= b.x + b.width)) and
           ((a.y >= b.y and a.y <= b.y + b.height) or (a.y + a.height >= b.y and a.y + a.height <= b.y + b.height)) =>
           @data[i].nb.show = false

    @render!
