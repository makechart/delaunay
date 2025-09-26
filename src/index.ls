module.exports =
  pkg:
    name: 'scatter', version: '0.0.1'
    extend: {name: "@makechart/base"}
    dependencies: [
      { url: "https://cdn.jsdelivr.net/npm/d3-delaunay@6/dist/d3-delaunay.min.js" }
    ]

  init: ({root, context, pubsub}) ->
    pubsub.fire \init, mod: mod {context}

mod = ({context}) ->
  {d3,chart} = context
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
    <[view yaxis xaxis]>.map ~> @{}g[it] = d3.select(@layout.get-group(it))
    @path = d3.select @svg .append \path

  parse: ->

  resize: ->
    [w,h] = [@box.width, @box.height]
    @extent =
      x: d3.extent @data.map -> it.x
      y: d3.extent @data.map -> it.y
    box = @layout.get-box \view
    @scale =
      x: d3.scaleLinear!domain @extent.x .range [0, box.width]
      y: d3.scaleLinear!domain @extent.y .range [0, box.height]
    @pts = @data.map (d) ~> [@scale.x(d.x), @scale.y(d.y)]
    @delaunay = d3.Delaunay.from @pts
    @voronoi = @delaunay.voronoi [0, 0, box.width, box.height]
    @cells = @pts
      .map (point,i) ~>
        [x,y] = point
        polygon = @voronoi.cellPolygon i
        [cx,cy] = centroid = d3.polygonCentroid polygon
        area = -d3.polygonArea polygon
        angle = (Math.round(Math.atan2(cy - y, cx - x) / Math.PI * 2) + 4) % 4
        {point, polygon, centroid, area, angle}

  render: ->
    {scale} = @
    @g.view.selectAll \circle.data .data @data
      ..exit!remove!
      ..enter!append \circle .attr \class, \data
        .attr \cx, (d,i) -> scale.x d.x
        .attr \cy, (d,i) -> scale.y d.y
        .attr \r, 3
        .attr \fill, \#000
    @g.view.selectAll \text .data @data
      ..exit!remove!
      ..enter!append \text
        .text (d,i) -> d.name
        .attr \x, (d,i) -> if d.nb => d.nb.x else scale.x(d.x)
        .attr \y, (d,i) -> if d.nb => d.nb.y else scale.y(d.y)
        .attr \text-anchor, \middle
        .attr \dominant-baseline, \middle
    @g.view.selectAll \text .data @data
      .attr \x, (d,i) -> if d.nb => d.nb.x else scale.x(d.x)
      .attr \y, (d,i) -> if d.nb => d.nb.y else scale.y(d.y) - 20
      .attr \opacity, (d,i) -> if d.nb => (if d.nb.show => 1 else 0) else 1
    @path
      .attr \d, @voronoi.render!
      .attr \stroke, \#000
      .attr \transform, @g.view.node!getAttribute(\transform)
  tick: ->
    scale = @scale
    @g.view.selectAll \text .each (d,i) -> d.box = @getBoundingClientRect!
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
