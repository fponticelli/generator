import thx.core.Error;

using thx.core.AnonymousMap;
using thx.core.Arrays;

import sys.FileSystem;
import sys.io.File;
import thx.tpl.Template;

class Generator {
  public var templateDirectory : String;
  public var destinationDirectory : String;
  public function new(templateDirectory : String, destinationDirectory : String) {
    this.templateDirectory = templateDirectory;
    this.destinationDirectory = destinationDirectory;
  }

  function ensureDirectory(base : String, path : String) {
    var sec = path.split('/');
    sec.pop();
    while(sec.length > 0) {
      base += sec.shift() + '/';
      if(!FileSystem.exists(base))
        FileSystem.createDirectory(base);
    }
  }

  public function generate(definition : Definition) {
    var content = try
                    File.getContent(templateDirectory+definition.template)
                  catch(e : Dynamic)
                    throw new Error('Unable to open file ${definition.template}');
    var template =  try
                      new Template(content)
                    catch(e : Dynamic)
                      throw new Error('Unable to parse the template: $e');
    var path =  try
                  new Template(definition.output)
                catch(e : Dynamic)
                  throw new Error('Unable to parse the path template: $e');

    var values = definition.values;
    values.mapi(function(value, i) {
      // inject other definitions
      value.values = values.slice(0, i).concat(values.slice(i+1, values.length));
      var map = new AnonymousMap(value),
          transformed = try template.execute(map) catch(e : Dynamic) throw new Error('template error: $e'),
          file   = try path.execute(map) catch(e : Dynamic) throw new Error('path error: $e'),
          append = file.substr(0, 1) == '+',
          output = destinationDirectory + (append ? (file = file.substr(1)) : file);
      if(FileSystem.exists(output) && FileSystem.isDirectory(output))
        throw new Error('Generated output "$output" is conflicting with an existing directory');

      ensureDirectory(destinationDirectory, file);

      var write = append ? File.append(output, false) : File.write(output, false);
      write.writeString(transformed);
      write.close();
    });
  }

  public function validate(definition : Definition) {
    if(null == definition.template)
      throw new Error('template field is not defined');
    if(!FileSystem.exists(templateDirectory+definition.template))
      throw new Error('Template file doesn\'t exist: ${definition.template}');
    if(FileSystem.isDirectory(templateDirectory+definition.template))
      throw new Error('Template is a directory and not a file: ${definition.template}');
    if(null == definition.values)
      throw new Error('values field is not defined');
    if(!Std.is(definition.values, Array))
      throw new Error('values field is not an array of values');
    if(definition.values.length == 0)
      throw new Error('values field is empty');
    if(null == definition.output)
      throw new Error('output field is not defined');
  }
}

typedef Definition = {
  template : String,
  output : String,
  values : Array<Dynamic>
}