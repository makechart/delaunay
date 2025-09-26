(function(){
  var mod;
  module.exports = {
    pkg: {
      name: 'scatter',
      version: '0.0.1',
      extend: {
        name: "base",
        version: "0.0.1"
      },
      dependencies: [{
        url: "https://cdn.jsdelivr.net/npm/d3-delaunay@6/dist/d3-delaunay.min.js"
      }]
    },
    init: function(arg$){
      var root, context, pubsub;
      root = arg$.root, context = arg$.context, pubsub = arg$.pubsub;
      return pubsub.fire('init', {
        mod: mod({
          context: context
        })
      });
    }
  };
  mod = function(arg$){
    var context, d3, chart, names;
    context = arg$.context;
    d3 = context.d3, chart = context.chart;
    names = ["The Glenn Miller Story", "The Fifth Element", "Forrest Gump", "Finding Nemo", "The Fly", "First Blood", "You Can't Take It with You", "Man of the Year", "From Hell", "The Easy Rider", "The English Patient", "The Extra-Terrestial", "Edward Scissorhands", "Empire of the Sun", "Encounters of the Third Kind", "Elizabeth: The Golden Age"];
    return {
      sample: function(){
        return {
          raw: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100].map(function(val){
            var ret;
            ret = {
              x: Math.random(),
              y: Math.random(),
              name: names[Math.floor(Math.random() * names.length)]
            };
            return ret;
          }),
          binding: {
            x: {
              key: 'x'
            },
            y: {
              key: 'y'
            },
            name: {
              key: 'name'
            }
          }
        };
      },
      config: {},
      dimension: {
        x: {
          type: 'R',
          name: "x axis"
        },
        y: {
          type: 'R',
          name: "y axis"
        },
        radius: {
          type: 'R',
          name: "radius"
        },
        category: {
          type: 'CN',
          name: "category"
        },
        name: {
          type: 'N',
          name: "name"
        }
      },
      init: function(){
        var tint, this$ = this;
        this.tint = tint = new chart.utils.tint();
        ['view', 'yaxis', 'xaxis'].map(function(it){
          return (this$.g || (this$.g = {}))[it] = d3.select(this$.layout.getGroup(it));
        });
        return this.path = d3.select(this.svg).append('path');
      },
      parse: function(){},
      resize: function(){
        var ref$, w, h, box, this$ = this;
        ref$ = [this.box.width, this.box.height], w = ref$[0], h = ref$[1];
        this.extent = {
          x: d3.extent(this.data.map(function(it){
            return it.x;
          })),
          y: d3.extent(this.data.map(function(it){
            return it.y;
          }))
        };
        box = this.layout.getBox('view');
        this.scale = {
          x: d3.scaleLinear().domain(this.extent.x).range([0, box.width]),
          y: d3.scaleLinear().domain(this.extent.y).range([0, box.height])
        };
        this.pts = this.data.map(function(d){
          return [this$.scale.x(d.x), this$.scale.y(d.y)];
        });
        this.delaunay = d3.Delaunay.from(this.pts);
        this.voronoi = this.delaunay.voronoi([0, 0, box.width, box.height]);
        return this.cells = this.pts.map(function(point, i){
          var x, y, polygon, centroid, ref$, cx, cy, area, angle;
          x = point[0], y = point[1];
          polygon = this$.voronoi.cellPolygon(i);
          ref$ = centroid = d3.polygonCentroid(polygon), cx = ref$[0], cy = ref$[1];
          area = -d3.polygonArea(polygon);
          angle = (Math.round(Math.atan2(cy - y, cx - x) / Math.PI * 2) + 4) % 4;
          return {
            point: point,
            polygon: polygon,
            centroid: centroid,
            area: area,
            angle: angle
          };
        });
      },
      render: function(){
        var scale, x$, y$;
        scale = this.scale;
        x$ = this.g.view.selectAll('circle.data').data(this.data);
        x$.exit().remove();
        x$.enter().append('circle').attr('class', 'data').attr('cx', function(d, i){
          return scale.x(d.x);
        }).attr('cy', function(d, i){
          return scale.y(d.y);
        }).attr('r', 3).attr('fill', '#000');
        y$ = this.g.view.selectAll('text').data(this.data);
        y$.exit().remove();
        y$.enter().append('text').text(function(d, i){
          return d.name;
        }).attr('x', function(d, i){
          if (d.nb) {
            return d.nb.x;
          } else {
            return scale.x(d.x);
          }
        }).attr('y', function(d, i){
          if (d.nb) {
            return d.nb.y;
          } else {
            return scale.y(d.y);
          }
        }).attr('text-anchor', 'middle').attr('dominant-baseline', 'middle');
        this.g.view.selectAll('text').data(this.data).attr('x', function(d, i){
          if (d.nb) {
            return d.nb.x;
          } else {
            return scale.x(d.x);
          }
        }).attr('y', function(d, i){
          if (d.nb) {
            return d.nb.y;
          } else {
            return scale.y(d.y) - 20;
          }
        }).attr('opacity', function(d, i){
          if (d.nb) {
            if (d.nb.show) {
              return 1;
            } else {
              return 0;
            }
          } else {
            return 1;
          }
        });
        return this.path.attr('d', this.voronoi.render()).attr('stroke', '#000').attr('transform', this.g.view.node().getAttribute('transform'));
      },
      tick: function(){
        var scale, rbox, i$, to$, i, d, ref$, r, j$, k$, j, a, b, data;
        scale = this.scale;
        this.g.view.selectAll('text').each(function(d, i){
          return d.box = this.getBoundingClientRect();
        });
        rbox = this.layout.getBox('view');
        for (i$ = 0, to$ = this.data.length; i$ < to$; ++i$) {
          i = i$;
          d = this.data[i].box;
          if (!this.data[i].nb) {
            this.data[i].nb = {
              x: scale.x(this.data[i].x),
              y: scale.y(this.data[i].y) - 20
            };
          }
          ref$ = this.data[i].nb;
          ref$.width = d.width;
          ref$.height = d.height;
          ref$.show = true;
        }
        for (i$ = 20; i$ < 200; i$ += 20) {
          r = i$;
          for (j$ = 0, to$ = this.data.length; j$ < to$; ++j$) {
            i = j$;
            for (k$ = 0; k$ < i; ++k$) {
              j = k$;
              ref$ = [this.data[i].nb, this.data[j].nb], a = ref$[0], b = ref$[1];
              if (((a.x >= b.x && a.x <= b.x + b.width) || (a.x + a.width >= b.x && a.x + a.width <= b.x + b.width)) && ((a.y >= b.y && a.y <= b.y + b.height) || (a.y + a.height >= b.y && a.y + a.height <= b.y + b.height))) {
                d = Math.random() * Math.PI * 2;
                data = this.data[i];
                ref$ = data.nb;
                ref$.x = scale.x(data.x) + Math.cos(d) * r;
                ref$.y = scale.y(data.y) + Math.sin(d) * r;
              }
            }
          }
        }
        for (i$ = 0, to$ = this.data.length; i$ < to$; ++i$) {
          i = i$;
          for (j$ = 0; j$ < i; ++j$) {
            j = j$;
            ref$ = [this.data[i].nb, this.data[j].nb], a = ref$[0], b = ref$[1];
            if (((a.x >= b.x && a.x <= b.x + b.width) || (a.x + a.width >= b.x && a.x + a.width <= b.x + b.width)) && ((a.y >= b.y && a.y <= b.y + b.height) || (a.y + a.height >= b.y && a.y + a.height <= b.y + b.height))) {
              this.data[i].nb.show = false;
            }
          }
        }
        return this.render();
      }
    };
  };
}).call(this);
