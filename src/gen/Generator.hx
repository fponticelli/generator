package gen;

import thx.load.Loader;
using thx.promise.Promise;
using thx.tpl.Template;
using thx.Error;
using thx.AnonymousMap;
using thx.Objects;
using thx.Maps;

class Generator {
  public static function load(path : String, ?dataPath : String) : Promise<Array<Generator>> {
    return Loader.getObject(path)
      .mapSuccess(function(ob) {
        var data = null == dataPath ? ob : Objects.getPath(ob, dataPath);
        if(null == data) throw new Error('no data in $ob at data path $dataPath');
        var arr : Array<{}>;
        if(data == ob) {
          if(Std.is(data, Array)) {
            arr == data;
          } else {
            arr = [data];
          }
        } else {
          if(Std.is(data, Array)) {
            arr = (cast data : Array<{}>).map(function(item) {
                    return Objects.copyTo(item, Objects.clone(ob, true), true);
                  });
          } else {
            arr = [Objects.copyTo(data, Objects.clone(ob, true), true)];
          }
        }
        return arr.map(function(data) return new Generator(data));
      });
  }

  var data : {};
  public function new(data : {}) {
    this.data = data;
  }

  public function run(content : String) {
    var template =  try
                      new Template(content)
                    catch(e : Dynamic)
                      throw new Error('Unable to parse the template: $e');
    var map = defaultMap(),
        dataMap = Objects.toMap(data);
    dataMap.copyTo(map);
    var generated = try template.execute(map) catch(e : Dynamic) throw new Error('template error: $e');
    return generated;
  }

  function defaultMap() : Map<String, Dynamic> {
    return [
      "Arrays" => thx.Arrays,
      "Bools" => thx.Bools,
      "Dates" => thx.Dates,
      "Enums" => thx.Enums,
      "ERegs" => thx.ERegs,
      "Floats" => thx.Floats,
      "Functions" => thx.Functions,
      "Ints" => thx.Ints,
      "Iterables" => thx.Iterables,
      "Iterators" => thx.Iterators,
      "Maps" => thx.Maps,
      "Objects" => thx.Objects,
      "Options" => thx.Options,
      "Strings" => thx.Strings,
      "Uuid" => thx.Uuid,

      "Math" => Math,
      "StringTools" => StringTools,
    ];
  }
}
