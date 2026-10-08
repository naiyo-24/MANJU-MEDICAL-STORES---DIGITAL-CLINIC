import 'dart:io';

void main() {
  final file = File('lib/screens/counter/inventory_screen.dart');
  var content = file.readAsStringSync();

  // Find the LayoutBuilder return block
  content = content.replaceFirst(
    '''
          return isScreenShort
              ? SingleChildScrollView(
                  child: SizedBox(
                    height: screenConstraints.maxHeight < 850 ? 850 : screenConstraints.maxHeight,
                    child: content,
                  ),
                )
              : content;
''',
    '''
          Widget wrapper = content;
          
          if (screenConstraints.maxHeight < 850) {
            wrapper = SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                height: 850,
                child: wrapper,
              ),
            );
          }
          
          if (screenConstraints.maxWidth < 600) {
            wrapper = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(screenConstraints.maxWidth, 600),
                child: wrapper,
              ),
            );
          }
          
          return wrapper;
'''
  );
  
  file.writeAsStringSync(content);
}
