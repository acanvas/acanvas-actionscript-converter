## Acanvas Converter

Convert pure Actionscript to Dart/StageXL.

### Target Audience

As an Actionscript developer, you've probably heard about [Dart](https://www.dartlang.org/) and [StageXL](http://www.stagexl.org/) by now and always wanted to give it a shot. 
If you're like me, you'd have an ActionScript project or at least a few classes ready, that you would want to port just to see how things work out in Standard Land. 
Because, let's face it, Flash in the browser doesn't have a future.

So, I went down this path in 2014...

### About Acanvas Converter

With the Dart syntax and StageXL API being quite similar to ActionScript and Flash's display list, I wondered if I could port over to Dart in an automated way.
I had a look at Abstract Syntax Tree conversion, but dropped it in favor of string manipulation through Regular Expressions.
This made it easy to compare the converted file with the original, which greatly helps when fixing errors. And there will be errors for sure. Remember, Acanvas Converter is just a helper :-)  
After a week of intense RegEx meditation (it was crazy), I was able to automate things enough to rely on the Dart Analyzer to identify any remaining conversion errors or incompatible APIs.

So, have fun with this script, which will take up to 1337% of pain out of the process, so that you can concentrate on converting just the instructions that matter. Look further down to get an idea where the helper helps.

If you would like to know what evolved out of this tool since I wrote it during summer 2014, go to [Acanvas CLI](https://github.com/acanvas/acanvas-generator).

## Acanvas Converter - Usage 

    $>  pub global activate --source git https://github.com/acanvas/acanvas-actionscript-converter
    
    # <PATH> can be absolute or relative.
    $> acanvas_converter --source <PATH> --target <PATH> --dart-package <DESIRED_PACKAGE_NAME>
    


## What Acanvas Converter does for you

### Packages
- replace package declarations with 'part of' directive
- add all classes to the library's package.dart (part 'src/...')
- converts CamelCase filenames to Dart specs (camel_case)

### Classes/Functions/Variables
- remove closing bracket at end of class
- reposition override keyword
- remove Event Metadata
- remove Bindable Metadata
- replace interface with abstract class
- remove 'final' from class declarations
- delete imports
- delete all scopes
- convert constructors (including calls to super)
- convert functions/getters/setters
- convert optional function parameters
- convert variable declarations, including const and final

### Type conversion
- '*' to dynamic
- Vector.<type> to List<type>
- Class to Type
- Number to num
- Boolean to bool
- uint to int
- Array to List (including .push to .add)
- Object to Map
- trace to print
- for each to for
- implicit comparators ('===' to '==')

### Misc
- convert (most) Math functions
- testing for null (in Dart, you can only do if(bool), all other need if(type != null))
- type casting: int(value) to (value).toInt()
- type casting: (Class)value to (value as Class)
- type casting: Class(value) to (value as Class)

### StageXL specific
- IEventDispatcher to EventDispatcher (yes, it works)
- getTimer to stage.juggler.elapsedTime*1000
- order of BitmapData.draw and BitmapData.fillColor (pure magic!)


## What Acanvas Converter does not do for you.   
Anything else. You'll have to manually deal with
- differences between the API's of StageXL and Flash's DisplayList.
- shortcomings of StageXL's DisplayList API's
- finding equivalents for all Flash API's not covered by StageXL

But hey, at least now you can focus on the important stuff! 


## Common Pitfalls after conversion

While there are other things impossible to automatically convert, the following two are encountered the most.

Everything is null by default:
int i;
i++; //null object error

You can't set List like this: 
list[list.length] = value; //out of bounds error

See http://www.stagexl.org/docs/actionscript-dart.html for more.
