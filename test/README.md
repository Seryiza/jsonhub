Fixture files live here.

Naming:
- `test/<script-name>.contains.json`

Behavior:
- `make check-via-playwrite <script-name>` loads the matching fixture.
- A fixture may be a single object or an array of objects.
- Matching is partial: each fixture object only needs to be contained inside one output object.
