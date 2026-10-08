import 'dart:io';

void main() {
  final file = File('lib/screens/counter/billing_screen.dart');
  var content = file.readAsStringSync();

  // Replace the return block in billing_screen
  content = content.replaceFirst(
    '''
                  if (isDesktopWidth) {
                    Widget content = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 13, child: leftSide),
                        const SizedBox(width: 24),
                        Expanded(flex: 9, child: rightSide),
                      ],
                    );
                    return hasEnoughHeight
                        ? content
                        : SingleChildScrollView(child: content);
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 500, // Fixed height so it doesn't shrink and overflow when keyboard opens
                            child: leftSide,
                          ),
                          const SizedBox(height: 24),
                          rightSide,
                        ],
                      ),
                    );
                  }
''',
    '''
                  Widget content;
                  if (isDesktopWidth) {
                    content = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 13, child: leftSide),
                        const SizedBox(width: 24),
                        Expanded(flex: 9, child: rightSide),
                      ],
                    );
                  } else {
                    content = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 600, // Fixed height so it doesn't shrink and overflow when keyboard opens
                            child: leftSide,
                          ),
                          const SizedBox(height: 24),
                          rightSide,
                        ],
                    );
                  }
                  
                  Widget wrapper = content;
                  
                  if (!hasEnoughHeight) {
                    wrapper = SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        height: 850,
                        child: wrapper,
                      ),
                    );
                  }
                  
                  if (constraints.maxWidth < 600) {
                    wrapper = SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 600,
                        child: wrapper,
                      ),
                    );
                  }
                  
                  return wrapper;
'''
  );
  
  file.writeAsStringSync(content);
}
