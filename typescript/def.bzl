load("@org_pubref_rules_node//node:rules.bzl", "npm_repository")

ts_filetype = FileType([".ts", ".tsx"])

def get_transitive_files(ctx):
  s = set()
  for dep in ctx.attr.deps:
    s += dep.transitive_files
  s += ctx.files.srcs
  return s

def str_join(j, l):
  return j.join(['"%s"' % x for x in l])

def dotdot(path):
  return '/'.join(['..' for p in path.split('/')][:-1]) + '/'

def ts_library_impl(ctx):
  return struct(
      files=set(),
      transitive_files=get_transitive_files(ctx))

def ts_binary_impl(ctx):
  files = list(get_transitive_files(ctx))
  output = ctx.outputs.out
  top = dotdot(ctx.outputs.tsconfig.path)

  ctx.template_action(
      template = ctx.file.tsconfig_,
      output = ctx.outputs.tsconfig,
      substitutions = {
        'OUT_FILE': top + output.path,
        'PATH_TO_TOP': top,
        'FILES': str_join(',\n', [top + f.path for f in ctx.files.srcs]),
        'ROOT_DIRS': str_join(',\n', [p + '/*' for p in [
            ctx.genfiles_dir.path,
            ctx.bin_dir.path,
            ctx.file.node_modules.path,
        ]]),
      }
  )

  ctx.action(
      inputs=files + ctx.files.node_modules + [ctx.outputs.tsconfig],
      outputs=[output, ctx.outputs.sourcemap],
      executable=ctx.executable.tsc_,
      env={
          "FLAGS": ' '.join(ctx.attr.flags + [
            # '--baseUrl', ctx.file.node_modules.path,
            # '--baseUrl', ctx.genfiles_dir,
            '-p', ctx.outputs.tsconfig.path,
          ]),
      },
      # arguments=["%s" % (output.path)] + \
      #     ["%s" % x.path for x in files],
  )

ts_library = rule(
  implementation = ts_library_impl,
  attrs = {
      "srcs": attr.label_list(allow_files=ts_filetype),
      "deps": attr.label_list(allow_files=False),
  },
)

ts_binary = rule(
    implementation = ts_binary_impl,
    attrs = {
        "tsc_": attr.label(
            cfg = "host",
            default=Label("//typescript:run"),
            allow_files=True,
            executable=True),
        "deps": attr.label_list(allow_files=True),
        "srcs": attr.label_list(allow_files=ts_filetype),
        "flags": attr.string_list(),
        "node_modules": attr.label(single_file=True),
        "tsconfig_": attr.label(
            single_file=True,
            default=Label("//typescript:tsconfig")),
    },
    outputs = {
        "out": "%{name}.js",
        "sourcemap": "%{name}.js.map",
        "tsconfig": "tsconfig.json",
    }
)

def typescript_repositories():
    npm_repository(
        name = "npm_typescript",
        deps = {
            "typescript": "2.2.0-dev.20161130",
        },
        #sha256 = "9075f59a2b279d68532a48484366c69f0cfa970be6e917b4f36641785a93c3bd"
    )
