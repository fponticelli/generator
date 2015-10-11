import mcli.CommandLine;
import sys.FileSystem;
import thx.load.Loader;

class Main extends CommandLine {

  public static function main()
    new mcli.Dispatch(Sys.args()).dispatch(new Main());

    /**
        Verbose mode
        @alias v
    **/
    public var verbose : Bool;

    /**
        Template directory
        @alias t
    **/
    public var templates : String;

    /**
        Destination directory
        @alias d
    **/
    public var destination : String;

    /**
        Base directory
        @alias b
    **/
    public var baseDir : String;

    function sanitizeDirectory(dir : String) {
      if(null == dir || '' == dir || '.' == dir || './' == dir)
        return baseDir;
      if(dir.substr(dir.length-1) != '/')
        dir = '$dir/';
      if(dir.substr(0, 1) != '/')
        return '$baseDir$dir';
      return dir;
    }

    function sanitizeFile(file : String) {
      if(file.substr(0, 1) != '/')
        return '$baseDir$file';
      return file;
    }

    function error(msg : String) {
      Sys.println(msg);
      Sys.exit(1);
      return null;
    }

    public function runDefault(varArgs : Array<String>) {
      if(null == baseDir)
        baseDir = Sys.getCwd();

      templates = sanitizeDirectory(templates);
      destination = sanitizeDirectory(destination);

      varArgs = varArgs.map(sanitizeFile);

      var generator = new Generator(templates, destination);

      varArgs.map(function(path) {
        Loader.getObject(Loader.normalizePath(path))
          .success(function(ob) {
            try
              generator.validate(ob)
            catch(e : thx.Error)
              error(e.message)
            catch(e : Dynamic)
              error('VALIDATION ERROR ${Std.string(e)}');

            try
              generator.generate(ob)
            catch(e : thx.Error)
              error(e.message)
            catch(e : Dynamic)
              error('ERROR ${Std.string(e)}');
            if(verbose)
              Sys.println('generated files for $path');
          })
          .throwFailure();
      });
    }

    public function help() {
        Sys.println(this.showUsage().split("\n").map(StringTools.rtrim).join("\n"));
        Sys.exit(0);
    }
}
