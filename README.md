## Röckdöt Converter - Pure Actionscript to StageXL Conversion Helper

### Target Audience

As an Actionscript developer, you've probably heard about [Dart](https://www.dartlang.org/) and [StageXL](http://www.stagexl.org/) by now and always wanted to give it a shot. 
If you're like me, you'd have an ActionScript project or at least a few classes ready, that you would want to port just to see how things work out in Standard Land. 
Because, let's face it, Flash in the browser doesn't have a future.

So, I went down this path in 2014...

### About Röckdöt Converter

With the Dart syntax and StageXL API being quite similar to ActionScript, I wondered how I could port over to Dart in the laziest way possible, with as much automation as possible.
I spent a bit on Abstract Syntax Tree conversion, but dropped it in favor of good old search and replace via Regular Expressions, 
in order to be able to manually compare the converted file with the original in case of errors (which definitely will occur). 
After a week of intense RegEx meditation (it was crazy), I was able to automate most of what's possible, more than enough to rely on the Dart Analyzer to identify any remaining conversion errors or incompatible APIs.

So, have fun with this script, which will take up to 174% of pain out of the process, so that you can concentrate on converting just the instructions that matter. Look further down to get an idea where the helper helps.

If you would like to see what evolved out of this tool I wrote in the summer of 2014, go to [Röckdöt Generator](https://github.com/blockforest/rockdot_generator). 

## Röckdöt Converter - Usage 

    $>  pub global activate --source git https://github.com/blockforest/stagexl-converter-pubglobal
    
    # <PATH> can be absolute or relative.
    $> stagexl_converter --source <PATH> --target <PATH> --dart-package <DESIRED_PACKAGE_NAME>
    


## What Röckdöt Converter does for you

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


## What Röckdöt Converter does not do for you.   
Anything else. You'll have to manually deal with
- differences between the API's of StageXL and Flash's DisplayList.
- shortcomings of StageXL's DisplayList API's
- finding equivalents for all Flash API's not covered by StageXL

But hey, at least now you can focus on the important stuff! 


## Common Pitfalls you will tap into

Everything is null by default. Even numbers (MEH!).
Will fail:
int i;
i++;

You can't set List like this: list[list.length] = value;
A lot of AS people do it this way, though, because it is way more performant than Array.push

Also, see http://www.stagexl.org/docs/actionscript-dart.html for even more pitfalls.
