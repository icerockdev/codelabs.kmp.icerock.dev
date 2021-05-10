# IceRock codelabs for Kotlin Multiplatform

## Prerequisites

The project requires the following major dependencies:

- [Go](https://golang.org/dl/) language
- [Node.js](https://nodejs.org/en/download/) v10+ and [npm](https://www.npmjs.com/get-npm)
- [gsutil](https://cloud.google.com/storage/docs/gsutil_install)
- [claat](https://github.com/googlecodelabs/tools/tree/master/claat#install)

## Local setup

### Setup dependencies

```bash
npm install
```

### Set environment variables

```bash
export PATH="~/go/bin/:$PATH"
export PATH="./node_modules/.bin/:$PATH"
```

### Build codelabs from sources

```bash
./build.sh
```

### Run local server

```bash
gulp serve
```

## More details

* <https://github.com/googlecodelabs/tools> - CodeLabs tooling;
* <https://github.com/googlecodelabs/tools/tree/master/site> - site original setup;
* <https://github.com/googlecodelabs/tools/tree/master/claat/parser/md> - guide for markdown
  CodeLabs;

