package gen;

import thx.Error;
import thx.Path;
import thx.promise.Promise;
import thx.load.Loader;
using hxargs.Args;
import sys.FileSystem;
import sys.io.File;

class Main {
  public static function main() {
    var args = Sys.args(),
        cfg  = {
          input : null,
          output : null,
          data : null,
          path : null
        };

    var cmd = Args.generate([
          @doc("input file template")
          ["-i", "--input"] => function(path : String) {
            if(cfg.input != null) throw new Error('input has been set already to ${cfg.input}');
            cfg.input = path;
          },

          @doc("output file path")
          ["-o", "--output"] => function(path : String) {
            if(cfg.output != null) throw new Error('output has been set already to ${cfg.output}');
            cfg.output = path;
          },

          @doc("data file path")
          ["-d", "--data"] => function(path : String) {
            if(cfg.data != null) throw new Error('data has been set already to ${cfg.data}');
            cfg.data = path;
          },

          @doc("path to a value inside data that is going to be used to populate the template (default to root)")
          ["-p", "--path"] => function(path : String) {
            if(cfg.path != null) throw new Error('path has been set already to ${cfg.path}');
            cfg.path = path;
          },

          _ => function(arg:String) throw new Error("Unknown command: " +arg)
        ]);

    if(args.length == 0) {
      print(cmd.getDoc());
      exit();
    } else {
      try {
        cmd.parse(args);
        if(null == cfg.input)  throw "--input (-i) missing";
        if(null == cfg.output) throw "--output (-o) missing";
        if(null == cfg.data)   throw "--data (-d) missing";

        cfg.input = Loader.normalizePath(cfg.input);
        cfg.data = Loader.normalizePath(cfg.data);

        Generator.load(cfg.data, cfg.path)
          .mapSuccessPromise(function(gens) {
            return Promise.all(gens.map(function(gen) {
              var input = gen.run(cfg.input);
              return Loader.getText(input)
                .mapSuccess(function(template) return {
                  gen : gen,
                  template : template
                });
            }));
          })
          .success(function(os) {
            os.map(function(o) {
              var result = o.gen.run(o.template),
                  output : Path = o.gen.run(cfg.output);
              ensureDirectory(output.dir());
              File.saveContent(output, result);
            });
          })
          .failure(function(err) {
            error(err.message);
          });

      } catch(e : Dynamic) {
        error(Std.string(e));
      }
    }
  }

  public static function ensureDirectory(path : Path) {
    var paths = path.hierarchy();
    for(path in paths) {
      var dir = path.toString();
      if(!FileSystem.exists(path))
        FileSystem.createDirectory(path);
    }
  }

  public static function print(message : String) {
    Sys.println(message);
  }

  public static function error(message : String, ?code : Int = 1) {
    print(message);
    exit(code);
  }

  public static function exit(?code : Int = 0) {
    Sys.exit(code);
  }
}
