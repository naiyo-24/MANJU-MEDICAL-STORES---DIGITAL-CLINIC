import re

with open('lib/screens/counter/billing_screen.dart', 'r') as f:
    text = f.read()

def remove_method(text, method_name):
    start_idx = text.find(method_name)
    if start_idx == -1:
        return text
    
    # step back to the start of the line or return type
    # find the previous newline before start_idx
    line_start = text.rfind('\n', 0, start_idx)
    if line_start != -1:
        # include the leading whitespace and annotations like `void` or `Widget`
        # actually, let's just find the first `{` after the method name
        open_brace = text.find('{', start_idx)
        if open_brace != -1:
            open_brackets = 1
            for i in range(open_brace + 1, len(text)):
                if text[i] == '{':
                    open_brackets += 1
                elif text[i] == '}':
                    open_brackets -= 1
                    
                if open_brackets == 0:
                    # remove from line_start to i + 1
                    return text[:line_start] + text[i+1:]
    return text

# Remove unused imports
text = text.replace("import 'package:go_router/go_router.dart';\n", "")
text = text.replace("import 'package:pdf/widgets.dart' as pw;\n", "")

# Remove unused getters/methods
text = remove_method(text, 'int get _totalItems =>')
text = remove_method(text, '_showAddCustomerDialog')
text = remove_method(text, '_showAddCustomItemDialog')
text = remove_method(text, '_buildCompactField')
text = remove_method(text, '_buildFilterChip')
text = remove_method(text, '_buildConditionalExpanded')
text = remove_method(text, '_buildCustomerSearchField')

# In flutter analyze, _totalItems was just an unused declaration. Let's make sure it's gone.
# If `int get _totalItems =>` wasn't matched because of formatting, we can regex it.
text = re.sub(r'int\s+get\s+_totalItems\s*=>.*?;', '', text)

with open('lib/screens/counter/billing_screen.dart', 'w') as f:
    f.write(text)
