import re
import textwrap

from manuel import Manuel as BaseManuel
from manuel.codeblock import CodeBlock, execute_code_block


CODEBLOCK_START = re.compile(
    r"((^```python)|(^% invisible-code-block:\s+python)$)",
    re.MULTILINE,
)
CODEBLOCK_END = re.compile(r"(\n(?=```\n))|((?:% [\S ]*)\n(?=\n))")


def find_code_blocks(document):
    for region in document.find_regions(CODEBLOCK_START, CODEBLOCK_END):
        start_end = CODEBLOCK_START.search(region.source).end()
        source = textwrap.dedent(region.source[start_end:])
        # MyST comments
        source = re.sub(r'\n%[ ]?', '\n', source)
        source_location = "%s:%d" % (document.location, region.lineno)
        code = compile(source, source_location, "exec", 0, True)
        document.claim_region(region)
        region.parsed = CodeBlock(code, source)


class Manuel(BaseManuel):
    def __init__(self):
        BaseManuel.__init__(self, [find_code_blocks], [execute_code_block])
