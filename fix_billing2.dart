import 'dart:io';

void main() {
  final file = File('lib/screens/counter/billing_screen.dart');
  var content = file.readAsStringSync();

  // Replace the logic
  content = content.replaceFirst(
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
''',
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
                    if (constraints.maxWidth < 700) {
                      wrapper = SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 700,
                          child: wrapper,
                        ),
                      );
                    }
                    return wrapper;
                  } else {
                    Widget wrapper = SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 600, // Fixed height so it doesn't shrink and overflow when keyboard opens
                            child: leftSide,
                          ),
                          const SizedBox(height: 24),
                          rightSide,
                        ],
                      ),
                    );
                    
                    if (constraints.maxWidth < 400) {
                      wrapper = SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 400,
                          child: wrapper,
                        ),
                      );
                    }
                    return wrapper;
                  }
'''
  );
  
  file.writeAsStringSync(content);
}
