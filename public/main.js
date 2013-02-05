var Ferret = {
  manifests: []
}

Ferret.init = function(){
  var $container = $(".clips");

  Ferret.manifests.forEach(function(manifest){
    var $h2 = $("<h2>").text(manifest.name),
        $ul = $("<ul>")
          .attr("id", "group-" + manifest.name)
          .attr("class", "widgets");

    $container.append($h2);
    $container.append($ul);

    manifest.metrics.forEach(function(metric){
      Ferret.build(manifest, metric);
      Ferret.populate(manifest, metric);
    });
  });
};

Ferret.build = function(manifest, metric){
  var name = manifest.name;
  var $ul = $("#group-" + name),
      $li = $("<li>")
        .attr("class", "item")
        .attr("id", metric.source.replace(/\./g, "-")),
      $title = $("<div>")
        .attr("class", "item-meta")
        .text(metric.display),
      $percent = $("<div>")
        .attr("class", "item-canvas");

      $li.append($percent);
      $li.append($title);
      $ul.append($li);
};

Ferret.populate = function(manifest, metric){
  var name   = manifest.name,
      token  = Ferret.metricToken,
      params = {};

  params["limit"] = metric.limit;
  params["resolution"] = metric.resolution;

  var url = Ferret.metricsUrl + metric.measure;
  var headers = { Authorization: "Basic " + btoa("l2met:" + token) };

  $.ajax({
    url: url,
    headers: headers,
    data: params,
    fields: { withCredentials: true }
  })
  .done(function(json){
    json.forEach(function(m){
      if(m.source == metric.source && m.name == metric.measure)
        Ferret.fillIn(metric, m);
    });
  });
};

Ferret.fillIn = function(metric, m){
  var $el   = $("#" + metric.source.replace(/\./g, "-")),
      $percent = $el.find("div.item-canvas");

  $el.attr("class", "item " + Ferret.status(metric, m));
  $percent.text((Math.round(m.mean * 100 ) / 100) + "%");
};

Ferret.status = function(metric, m){
  var value  = m.mean,
      red    = metric["status-levels"]["red"],
      yellow = metric["status-levels"]["yellow"],
      green  = metric["status-levels"]["green"];

	if (m.mean <= red)
		return "red";
   else if (value <= yellow)
		return "yellow";
  else
    return "green";
};
