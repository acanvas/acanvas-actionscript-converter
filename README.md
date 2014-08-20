## Pure Actionscript to Dart Conversion Helper (Pub Edition)


As an Actionscript developer, you've probably heard about Dart and StageXL by now and always wanted to give it a shot. Of course, you have a project or just some classes ready, that you want to port just to see what's going on.

Let me tell you this: while working with the DisplayList in StageXL feels rather similar to what you know from Actionscript, everything else is so different that after converting half a class, you will either give up, or start from scratch.

Luckily, this little tool will take about 190% of the pain out of the process. It will get as much out of the way for you as possible, so that you can concentrate on converting just the instructions that matter. Look further down to get an idea where the helper helps.

#### By the way: 
You are looking at the Pub Edition of the converter.
If you are rather new to Dart, I'd recommend cloning/downloading the Dart Project Edition:
https://github.com/blockforest/actionscript-to-dart-project

## What it does for you

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


## What it does not do for you.   
Anything else. You'll have to manually deal with
- differences between the API's of StageXL and Flash's DisplayList.
- shortcomings of StageXL's DisplayList API's
- finding equivalents for all Flash API's not covered by StageXL

But hey, at least now you can focus on the important stuff! 

## Usage 
### Note: This package has not yet been published to pub. Be patient.
1. pub global activate as3_to_dart
2. See pub global run as3_to_dart:as3_to_dart --help

## Examples
Due to the nature of pub global packages, this edition comes without examples.
If you are new to Dart and want to see results, clone or Download the Dart Project Edition 
at https://github.com/blockforest/actionscript-to-dart-project

## Common Pitfalls you will tap into

Everything is null by default. Even numbers (MEH!).
Will fail:
int i;
i++;

You can't set List like this: list[list.length] = value;
A lot of AS people do it this way, though, because it is way more performant than Array.push

Also, see http://www.stagexl.org/docs/actionscript-dart.html for even more pitfalls.
