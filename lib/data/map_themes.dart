const themeMinimalWhite = [
  {
    "id": "background",
    "type": "background",
    "paint": {"background-color": "#cccccc"}
  },
  {
    "id": "earth",
    "type": "fill",
    "source": "protomaps",
    "source-layer": "earth",
    "minzoom": 6,
    "paint": {"fill-color": "#e0e0e0"}
  },
  {
    "id": "water",
    "type": "fill",
    "source": "protomaps",
    "source-layer": "water",
    "minzoom": 4,
    "paint": {"fill-color": "#cccccc"}
  },
  {
    "id": "boundaries_country",
    "type": "line",
    "source": "protomaps",
    "source-layer": "boundaries",
    "minzoom": 4,
    "filter": ["<=", "pmap:min_admin_level", 2],
    "paint": {
      "line-color": "#adadad",
      "line-width": 1,
      "line-dasharray": [3, 2]
    }
  },
  {
    "id": "boundaries_region",
    "type": "line",
    "source": "protomaps",
    "source-layer": "boundaries",
    "filter": ["!=", "pmap:kind", "country"],
    "paint": {
      "line-color": "#adadad",
      "line-width": 1,
      "line-dasharray": [3, 2]
    }
  }
];

const themeMinimalBlack = [
  {
    "id": "background",
    "type": "background",
    "paint": {"background-color": "#2b2b2b"}
  },
  {
    "id": "earth",
    "type": "fill",
    "source": "protomaps",
    "source-layer": "earth",
    "paint": {"fill-color": "#141414"}
  },
  {
    "id": "water",
    "type": "fill",
    "source": "protomaps",
    "source-layer": "water",
    "paint": {"fill-color": "#333333"}
  },
  {
    "id": "boundaries_country",
    "type": "line",
    "source": "protomaps",
    "source-layer": "boundaries",
    "filter": ["<=", "pmap:min_admin_level", 2],
    "paint": {
      "line-color": "#8c8c8c",
      "line-width": 1.5,
      "line-dasharray": [3, 2]
    }
  },
  {
    "id": "boundaries_region",
    "type": "line",
    "source": "protomaps",
    "source-layer": "boundaries",
    "filter": [
      "all",
      [">", "pmap:min_admin_level", 2],
      ["<=", "pmap:min_admin_level", 4]
    ],
    "paint": {
      "line-color": "#8c8c8c",
      "line-width": 0.75,
      "line-dasharray": [3, 2]
    }
  }
];
