import json
import sys

query = json.load(sys.stdin)
template_name = sys.argv[1]
input = json.loads(sys.argv[2])
query.update(input.get('query', {}))

try:
    print(json.dumps({
        "name": input["template"][template_name] % query
    }))
except KeyError as err:
    sys.stderr.write(
        "Template expected a query parameter '%s' in '%s'.\n" % (err.args[0], input["template"]))
    sys.exit(1)
