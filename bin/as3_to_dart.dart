import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart';

final String TEMPLATE_DIR = join(dirname(Platform.script.toFilePath()), "template");
const String TEMPLATE_LIBRARY_FILE = "library.dart.tpl";
const String TEMPLATE_PUBSPEC_FILE = "pubspec.yaml.tpl";
const String TEMPLATE_REPLACE_STRING = "@library@";

final String DEFAULT_SOURCE_DIR = join(dirname(Platform.script.toFilePath()), "examples");
const String DEFAULT_LIBRARY_NAME = "examples_autogen";
const String DEFAULT_TARGET_DIR = "lib";

String library_file_content;

String library_name;
String package;
String source_basedir;
String target_basedir;

void main(List args) {

  library_name = DEFAULT_LIBRARY_NAME;
  source_basedir = DEFAULT_SOURCE_DIR;
  target_basedir = DEFAULT_TARGET_DIR;

  _setupArgs(args);
  
  //read the library file template so we can append all classes found
  File librarySourceFile = new File(join(TEMPLATE_DIR, TEMPLATE_LIBRARY_FILE));
  library_file_content = librarySourceFile.readAsStringSync();
  library_file_content = library_file_content.replaceAll(new RegExp(TEMPLATE_REPLACE_STRING), library_name);

  /* iterate over source path, grab *.as files */
  Directory sourceDir = new Directory(source_basedir);
  if (sourceDir.existsSync()) {
    sourceDir.listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
      if (FileSystemEntity.typeSync(entity.path) == FileSystemEntityType.FILE && extension(entity.path).toLowerCase() == ".as") {
        _convert(entity.path);
      }
    });
    _copyTemplates();
    _addLibraryToRootPubspec();
  } else {
    print("The directory that was provided as source_basedir does not exist: $source_basedir");
    exit(1);
  }
}

/// Adds the newly created library as dependency to the project's root pubspec.yaml.
void _addLibraryToRootPubspec() {
  String insertionString = 
  '''
dependencies:
  $library_name:
    path: ${join(target_basedir, library_name)}''';
  
  File pubspecRootFile = new File('pubspec.yaml').absolute;
  String pubspecRootFileContent = pubspecRootFile.readAsStringSync();
  if(! pubspecRootFileContent.contains(library_name)){
    pubspecRootFileContent = pubspecRootFileContent.split(new RegExp("dependencies\\s*:")).join(insertionString);
    pubspecRootFile.writeAsStringSync( pubspecRootFileContent, mode: FileMode.WRITE);
  }
}

/// Copies template files from [TEMPLATE_DIR] into the newly created library.
/// During the process, all occurences of [TEMPLATE_REPLACE_STRING] are replaced.
void _copyTemplates() {
  //create library file
  new File(join(target_basedir, library_name, "$library_name.dart")).absolute
      ..createSync(recursive: true)
      ..writeAsStringSync(library_file_content);

  //create yaml file
  File pubspecSourceFile = new File(join(TEMPLATE_DIR, TEMPLATE_PUBSPEC_FILE));
  String pubspecFileContent = pubspecSourceFile.readAsStringSync();
  pubspecFileContent = pubspecFileContent.replaceAll(new RegExp(TEMPLATE_REPLACE_STRING), library_name);
  new File(join(target_basedir, library_name, "pubspec.yaml")).absolute
      ..createSync(recursive: true)
      ..writeAsStringSync(pubspecFileContent);
}

/// Takes a File path, e.g. bin/examples/wonderfl/xmas/StarUnit.as, and writes it to
/// the output directory provided, e.g. lib/examples_autogen/src/wonderfl/xmas/star_unit.dart.
/// During the process, excessive RegExp magic is applied.
void _convert(String asFilePath) {

  //e.g. bin/examples/wonderfl/xmas/StarUnit.as
  //print("asFilePath: $asFilePath");

  File asFile = new File(asFilePath);

  //File name, e.g. StarUnit.as
  String asFileName = basename(asFile.path);

  //Package name, e.g. wonderfl/xmas
  String dartFilePath = asFilePath.replaceFirst(new RegExp(source_basedir + "/"), "");
  dartFilePath = dirname(dartFilePath);
  //print("dartFilePath: $dartFilePath");

  //New filename, e.g. star_unit.dart
  String dartFileName = basenameWithoutExtension(asFile.path).replaceAllMapped(new RegExp("(IO|I|[^A-Z-])([A-Z])"), (Match m) => (m.group(1) + "_" + m.group(2))).toLowerCase();
  dartFileName += ".dart";
  //print("dartFileName: $dartFileName");

  String asFileContents = asFile.readAsStringSync();
  String dartFileContents = _applyMagic(asFileContents);

  //Write new file
  new File(join(target_basedir, library_name, "src", dartFilePath, dartFileName)).absolute
      ..createSync(recursive: true)
      ..writeAsStringSync(dartFileContents);

  library_file_content += "\npart 'src/$dartFilePath/$dartFileName';";
}

/// Applies magic to an ActionScript file String, converting it to almost error free Dart.
/// Note that the focus lies on the conversion of the Syntax tree and the most obvious
/// differences in the respective API's.
String _applyMagic(String f) {
// replace package declaration
  f = f.replaceAllMapped(new RegExp("(\\s*)package\\s+[a-z0-9.]+\\s*\\{"), (Match m) => "${m[1]} part of $library_name;");
  // remove closing bracket at end of class
  f = f.replaceAll(new RegExp("\\}\\s*\$"), "");
  // reposition override keyword
  f = f.replaceAllMapped(new RegExp("(\\s+)override(\\s+)"), (Match m) => "${m[1]}@override${m[2]}\n\t\t");
  // remove Event Metadata
  f = f.replaceAllMapped(new RegExp("(\\[Event\\(.*\\])"), (Match m) => "// ${m[1]}");
  // remove Bindable Metadata
  f = f.replaceAllMapped(new RegExp("(\\[Bindable\\(.*\\])"), (Match m) => "// ${m[1]}");
  // replace interface
  f = f.replaceAll(new RegExp("interface"), "abstract class");
  // remove 'final' from class declaration
  f = f.replaceAll(new RegExp("final\\s+class"), "class");
  // delete imports
  f = f.replaceAll(new RegExp(".*import.*(\r?\n|\r)?"), "");
  // delete all scopes
  f = f.replaceAll(new RegExp("public|private|protected"), "");
  // convert * datatype
  f = f.replaceAll(new RegExp(":\\s*(\\*)"), ": dynamic");
  // convert Vector syntax and datatype (i.e. Vector.<int> to List<int>)
  f = f.replaceAllMapped(new RegExp("Vector.([a-zA-Z0-9_<>]*)"), (Match m) => "List${m[1]}");

  // === constructors and functions ===
  // note: the unprocessed function parameters are enclosed by '%#'
  //       marks. These are replaced later.

  // constructors (detected by missing return type)
  f = f.replaceAllMapped(new RegExp("([a-z]*)\\s+function\\s+(\\w*)\\s*\\(\\s*" + "([^)]*)" + "\\s*\\)(\\s*\\{)"), (Match m) => "\n\t${m[1]} ${m[2]}(%#${m[3]}%#)${m[4]}");

  // getters/setters
  f = f.replaceAllMapped(new RegExp("([a-z]*\\s+)function\\s+(get|set)\\s+(\\w*)\\s*\\(\\s*" + "([^)]*)" + "\\s*\\)\\s*:\\s*([a-zA-Z0-9_.<>]*)"), (Match m) => "${m[1]} ${m[5]} ${m[2]} ${m[3]}(%#${m[4]}%#)");
  // remove empty parentheses from getters
  f = f.replaceAllMapped(new RegExp("([a-zA-Z]*\\s+get\\s+\\w*\\s*)\\(%#%#\\)"), (Match m) => "${m[1]}");


  // functions
  f = f.replaceAllMapped(new RegExp("([a-z]*\\s+)function\\s+(\\w*)\\s*\\(\\s*" + "([^)]*)" + "\\s*\\)\\s*:\\s*([a-zA-Z0-9_.<>]*)"), (Match m) => "${m[1]} ${m[4]} ${m[2]}(%#${m[3]}%#)");

  // deal with super call in constructor
  f = f.replaceAllMapped(new RegExp("(\\s*\\{)\\s*(super\\s*\\(.*\\));"), (Match m) => ": ${m[2]} ${m[1]}");
  // disable super(this) in constructor
  f = f.replaceAll(new RegExp("(super\\s*\\(this\\))"), "super(/*this*/)");


  // remove zero parameter marks
  f = f.replaceAll(new RegExp("%#\\s*%#"), "");

  // Now, replace unprocessed parameters (maximum 9 parameters)
  for (int i = 0; i < 9; i++) {
    // parameters w/o default values
    f = f.replaceAllMapped(new RegExp("%#\\s*(\\w*)\\s*:\\s*([a-zA-Z0-9_.<>]*)\\s*,"), (Match m) => "${m[2]} ${m[1]},%#"); //first param of several
    f = f.replaceAllMapped(new RegExp("%#\\s*(\\w*)\\s*:\\s*([a-zA-Z0-9_.<>]*)\\s*%#"), (Match m) => "${m[2]} ${m[1]}"); //last or only param in declaration

    // parameters w/ default values. a bit tricky as dart has a special way of defining optional arguments
    //first find
    f = f.replaceAllMapped(new RegExp("%#\\s*(\\w*)\\s*:\\s*([a-zA-Z0-9_.<>]*)\\s*=\\s*([^):,]*)\\s*,"), (Match m) => "[${m[2]} ${m[1]}=${m[3]}, %##");
    //other finds
    f = f.replaceAllMapped(new RegExp("%##\\s*(\\w*)\\s*:\\s*([a-zA-Z0-9_.<>]*)\\s*=\\s*([^):,]*)\\s*,"), (Match m) => "${m[2]} ${m[1]}=${m[3]}, %##");
    //last find
    f = f.replaceAllMapped(new RegExp("%##\\s*(\\w*)\\s*:\\s*([a-zA-Z0-9_.<>]*)\\s*=\\s*([^):,]*)\\s*%#"), (Match m) => "${m[2]} ${m[1]}=${m[3]}]");

    //if only one param:
    f = f.replaceAllMapped(new RegExp("%#\\s*(\\w*)\\s*:\\s*([a-zA-Z0-9_.<>]*)\\s*=\\s*([^):,]*)\\s*%#"), (Match m) => "[${m[2]} ${m[1]}=${m[3]}]");
  }

  // === variable declarations ===
  f = f.replaceAllMapped(new RegExp("var\\s+([a-zA-Z0-9_]*)\\s*:\\s*([a-zA-Z0-9_.<>]*)"), (Match m) => "${m[2]} ${m[1]}");

  // === const declarations ===
  f = f.replaceAllMapped(new RegExp("const\\s+([a-zA-Z0-9_]*)\\s*:\\s*([a-zA-Z0-9_]*)"), (Match m) => "const ${m[2]} ${m[1]}");
  f = f.replaceAll(new RegExp("static const"), "static final");
  // XXX multiple comma separated declarations not supported!

  // === typecasts ===
  // int(value) --> value.toInt()
  f = f.replaceAllMapped(new RegExp("\\s+int\\s*\\((.+)\\)"), (Match m) => "(${m[1]}).toInt()");
  // (Class) variable --> (variable as Class)
  f = f.replaceAllMapped(new RegExp("\\(([a-zA-Z^)]+)\\)\\s*(\\w+)"), (Match m) => "(${m[2]} as ${m[1]})");
  // Class(variable) --> (variable as Class)
  f = f.replaceAllMapped(new RegExp("^new([A-Z]+[a-zA-Z0-9]+)\\s*\\(\\s*(\\w+)\\s*\\)"), (Match m) => "(${m[2]} as ${m[1]})");


  //e.g. _ignoredRootViews ||= new List<DisplayObject>();
  f = f.replaceAllMapped(new RegExp("(\\w+)\\s*\\|\\|\\=(.+);"), (Match m) => "(${m[1]} != null) ? ${m[1]} :${m[1]} = ${m[2]};");


  // === more translations ===
  f = f.replaceAll(new RegExp("Class"), "Type");
  f = f.replaceAll(new RegExp("Number"), "num");
  f = f.replaceAll(new RegExp("Boolean"), "bool");
  f = f.replaceAll(new RegExp("uint"), "int");
  f = f.replaceAll(new RegExp("Array"), "List");
  f = f.replaceAll(new RegExp(".push"), ".add");
  f = f.replaceAll(new RegExp("Vector"), "List");
  f = f.replaceAll(new RegExp("Dictionary"), "Map");
  f = f.replaceAllMapped(new RegExp("(\\s+)Object"), (Match m) => "${m[1]}Map");
  f = f.replaceAll(new RegExp("trace"), "print");
  f = f.replaceAll(new RegExp("for\\s+each"), "for");
  f = f.replaceAll(new RegExp("!=="), "==");
  f = f.replaceAll(new RegExp("==="), "==");
  f = f.replaceAll(new RegExp(">>>"), ">>/*>*/"); //strange one, used by frocessing library
  f = f.replaceAllMapped(new RegExp("^:\\s(super\\(\\s*\\))"), (Match m) => "// ${m[1]}");

  //Math
  f = f.replaceAll(new RegExp("Math\\.PI"), "PI");
  f = f.replaceAll(new RegExp("Math\\.max"), "/*Math.*/max");
  f = f.replaceAll(new RegExp("Math\\.tan"), "/*Math.*/tan");
  f = f.replaceAll(new RegExp("Math\\.sin"), "/*Math.*/sin");
  f = f.replaceAll(new RegExp("Math\\.cos"), "/*Math.*/cos");
  f = f.replaceAll(new RegExp("Math\\.min"), "/*Math.*/min");
  f = f.replaceAllMapped(new RegExp("Math\\.floor\\((.+)\\)"), (Match m) => "(${m[1]}).floor()");
  f = f.replaceAllMapped(new RegExp("Math\\.ceil\\((.+)\\)"), (Match m) => "(${m[1]}).ceil()");
  f = f.replaceAllMapped(new RegExp("Math\\.round\\((.+)\\)"), (Match m) => "(${m[1]}).round()");
  f = f.replaceAllMapped(new RegExp("Math\\.abs\\((.+)\\)"), (Match m) => "(${m[1]}).abs()");
  f = f.replaceAll(new RegExp("Math\\.random\\(\\)"), "new Random().nextDouble()");
  f = f.replaceAllMapped(new RegExp("toFixed\\((\\d+)\\)"), (Match m) => "toStringAsFixed(${m[1]})");


  // === StageXL specific ===

  //change the order of color and fill instructions for Graphics and BitmapData
  f = f.replaceAllMapped(new RegExp("([a-zA-Z0-9\.]+beginFill\\(\\s*[a-fA-F0-9x]+\\s*\\)\\s*;)(\r?\n|\r)?(\\s*)([a-zA-Z0-9\.]+(drawRect|drawRoundRect)\\(\\s*[a-zA-Z0-9\.\\s*,\\s*]+\\s*\\)\\s*;)"), (Match m) => "${m[4]}${m[2]}${m[3]}${m[1]} //");
  //renaming
  f = f.replaceAll(new RegExp("beginFill"), "fillColor");
  f = f.replaceAll(new RegExp("drawRect"), "rect");
  f = f.replaceAll(new RegExp("drawRoundRect"), "rectRound");
  //endFill not supported/needed
  f = f.replaceAllMapped(new RegExp("([a-zA-Z0-9\.]+endFill\\(\\s*\\))"), (Match m) => "//${m[1]} //not supported in StageXL");
  //lock/unlock not supported/needed
  f = f.replaceAllMapped(new RegExp("([a-zA-Z0-9\.]+(lock|unlock)\\(\\s*\\))"), (Match m) => "//${m[1]} //not supported in StageXL");
  //smoothing not supported
  f = f.replaceAllMapped(new RegExp("([a-zA-Z0-9\.]+smoothing\\s*=\\s*.+;)"), (Match m) => "//${m[1]} //not supported in StageXL");

  //help out with TweenLite/TweenMax
  f = f.replaceAllMapped(new RegExp("(\\s*)(TweenLite|TweenMax)(\\.to\\(\\s*)([a-zA-Z0-9\.]+)(\\s*,\\s*[a-zA-Z0-9\.]+)(.+;)"), (Match m) => "${m[1]}${m[1]}//TODO ${m[1]}/* ${m[1]}//StageXL tweening works like this: ${m[1]}stage.juggler.tween(${m[4]} ${m[5]} /*, TransitionFunction.easeOutBounce */)${m[1]}  .animate.x.to( someValue ); ${m[1]}*/ ${m[1]}${m[2]}${m[3]}${m[4]}${m[5]}${m[6]}${m[1]}");

  //Geometry
  f = f.replaceAll(new RegExp("new\\s+Point\\(\\)"), "new Point(0,0)");

  //Timer
  f = f.replaceAll(new RegExp("getTimer\\(\\)"), "/*getTimer()*/ (stage.juggler.elapsedTime*1000)");

  //no IEventDispatcher in StageXL
  f = f.replaceAll(new RegExp("IEventDispatcher"), "/*I*/EventDispatcher");

  //when testing for null, this works in as3: if(variable). In Dart, everything other than a bool needs if(variable != null)
  f = f.replaceAllMapped(new RegExp("if\\s*\\(\\s*([a-zA-Z0-9]+)\\s*\\)"), (Match m) => "if( ${m[1]} != null || ${m[1]} == true)");
  f = f.replaceAllMapped(new RegExp("if\\s*\\(\\s*!\\s*([a-zA-Z0-9]+)\\s*\\)"), (Match m) => "if( ${m[1]} == null || ${m[1]} == false)");

  return f;
}

/// Manages the script's arguments and provides instructions and defaults for the --help option.
void _setupArgs(List args) {
  ArgParser argParser = new ArgParser();
  argParser.addOption('library', abbr: 'l', defaultsTo: DEFAULT_LIBRARY_NAME, help: 'The name of the library to be generated.', valueHelp: 'library', callback: (_library) {
    library_name = _library;
  });
  argParser.addOption('package', abbr: 'p', defaultsTo: "", help: 'The as3 package to be converted, e.g. com/my/package. If omitted, everything found under the --source directory provided will get converted.', valueHelp: 'package', callback: (_package) {
    package = _package;
  });
  argParser.addOption('source', abbr: 's', defaultsTo: DEFAULT_SOURCE_DIR, help: 'The path (relative or absolute) to the Actionscript source(s) to be converted.', valueHelp: 'source', callback: (_source_basedir) {
    source_basedir = _source_basedir;
  });
  argParser.addOption('target', abbr: 't', defaultsTo: DEFAULT_TARGET_DIR, help: 'The path (relative or absolute) the generated Dart library will be written to. Usually, your Dart project\'s \'lib\' directory.', valueHelp: 'target', callback: (_target_basedir) {
    target_basedir = _target_basedir;
  });


  argParser.addFlag('help', negatable: false, help: 'Displays the help.', callback: (help) {
    if (help) {
      print(argParser.getUsage());
      exit(1);
    }
  });

  argParser.parse(args);
}
