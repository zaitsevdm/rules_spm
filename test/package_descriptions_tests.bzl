load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//spm/internal:package_descriptions.bzl",
    "module_types",
    pds = "package_descriptions",
)
load(":json_test_data.bzl", "package_description_json")

def _parse_json_test(ctx):
    env = unittest.begin(ctx)

    pkg_desc = pds.parse_json(package_description_json)
    asserts.equals(env, 3, len(pkg_desc["targets"]))

    return unittest.end(env)

parse_json_test = unittest.make(_parse_json_test)

def _exported_library_targets_test(ctx):
    env = unittest.begin(ctx)

    pkg_desc = pds.parse_json(package_description_json)
    result = pds.exported_library_targets(pkg_desc)
    asserts.equals(env, 1, len(result))
    asserts.equals(env, "Logging", result[0]["c99name"])

    pkg_desc = {
        "products": [
            {"name": "Foo", "type": {"library": {}}, "targets": ["Foo"]},
            {"name": "Bar", "type": {"library": {}}, "targets": ["Bar"]},
        ],
        "targets": [
            {"name": "Foo", "target_dependencies": ["Bar", "Hello"]},
            {"name": "Bar", "target_dependencies": ["Hello"]},
            {"name": "Hello", "target_dependencies": []},
        ],
    }
    actual = sorted([t["name"] for t in pds.exported_library_targets(pkg_desc, product_names = ["Foo"])])
    expected = ["Foo"]
    asserts.equals(env, expected, actual)

    actual = sorted([t["name"] for t in pds.exported_library_targets(pkg_desc, with_deps = True)])
    expected = ["Bar", "Foo", "Hello"]
    asserts.equals(env, expected, actual)

    actual = sorted([t["name"] for t in pds.exported_library_targets(pkg_desc, product_names = ["Foo"], with_deps = True)])
    expected = ["Bar", "Foo", "Hello"]
    asserts.equals(env, expected, actual)

    actual = sorted([t["name"] for t in pds.exported_library_targets(pkg_desc, product_names = ["Bar"], with_deps = True)])
    expected = ["Bar", "Hello"]
    asserts.equals(env, expected, actual)

    return unittest.end(env)

exported_library_targets_test = unittest.make(_exported_library_targets_test)

def _is_library_product_test(ctx):
    env = unittest.begin(ctx)

    product = {"type": {"library": {}}}
    asserts.true(env, pds.is_library_product(product))
    product = {"type": {"executable": None}}
    asserts.false(env, pds.is_library_product(product))

    return unittest.end(env)

is_library_product_test = unittest.make(_is_library_product_test)

def _library_products_test(ctx):
    env = unittest.begin(ctx)

    pkg_desc = {
        "products": [
            {"name": "Foo", "type": {"library": {}}},
            {"name": "Chicken", "type": {"executable": None}},
            {"name": "Bar", "type": {"library": {}}},
        ],
    }
    result = pds.library_products(pkg_desc)
    asserts.equals(env, 2, len(result))
    product_names = [p["name"] for p in result]
    asserts.true(env, "Foo" in product_names)
    asserts.true(env, "Bar" in product_names)

    pkg_desc = {
        "products": [],
    }
    result = pds.library_products(pkg_desc)
    asserts.equals(env, 0, len(result))

    return unittest.end(env)

library_products_test = unittest.make(_library_products_test)

def _is_library_target_test(ctx):
    env = unittest.begin(ctx)

    target = {"type": "library"}
    asserts.true(env, pds.is_library_target(target))
    target["type"] = "executable"
    asserts.false(env, pds.is_library_target(target))

    return unittest.end(env)

is_library_target_test = unittest.make(_is_library_target_test)

def _library_targets_test(ctx):
    env = unittest.begin(ctx)

    pkg_desc = {
        "targets": [
            {"name": "Foo", "type": "library"},
            {"name": "Chicken", "type": "executable"},
            {"name": "Bar", "type": "library"},
        ],
    }
    result = pds.library_targets(pkg_desc)
    asserts.equals(env, 2, len(result))
    target_names = [t["name"] for t in result]
    asserts.true(env, "Foo" in target_names)
    asserts.true(env, "Bar" in target_names)

    return unittest.end(env)

library_targets_test = unittest.make(_library_targets_test)

def _dependency_name_test(ctx):
    env = unittest.begin(ctx)

    pkg_dep = {"name": "foo-kit", "url": "https://github.com/swift-server/async-http-client.git"}
    asserts.equals(env, "foo-kit", pds.dependency_name(pkg_dep))

    pkg_dep = {"url": "https://github.com/swift-server/async-http-client.git"}
    asserts.equals(env, "async-http-client", pds.dependency_name(pkg_dep))

    return unittest.end(env)

dependency_name_test = unittest.make(_dependency_name_test)

def _dependency_repository_name_test(ctx):
    env = unittest.begin(ctx)

    pkg_dep = {"url": "https://github.com/swift-server/async-http-client.git"}
    asserts.equals(env, "async-http-client", pds.dependency_repository_name(pkg_dep))

    return unittest.end(env)

dependency_repository_name_test = unittest.make(_dependency_repository_name_test)

def _is_clang_target_test(ctx):
    env = unittest.begin(ctx)

    target = {"module_type": module_types.clang}
    asserts.true(env, pds.is_clang_target(target))

    target = {"module_type": module_types.swift}
    asserts.false(env, pds.is_clang_target(target))

    return unittest.end(env)

is_clang_target_test = unittest.make(_is_clang_target_test)

def _is_swift_target_test(ctx):
    env = unittest.begin(ctx)

    target = {"module_type": module_types.swift}
    asserts.true(env, pds.is_swift_target(target))

    target = {"module_type": module_types.clang}
    asserts.false(env, pds.is_swift_target(target))

    return unittest.end(env)

is_swift_target_test = unittest.make(_is_swift_target_test)

def _get_target_test(ctx):
    env = unittest.begin(ctx)

    pkg_desc = pds.parse_json(package_description_json)
    result = pds.get_target(pkg_desc, "Logging")
    asserts.equals(env, "Logging", result["name"])

    return unittest.end(env)

get_target_test = unittest.make(_get_target_test)

def package_descriptions_test_suite():
    unittest.suite(
        "package_description_tests",
        parse_json_test,
        exported_library_targets_test,
        is_library_product_test,
        library_products_test,
        is_library_target_test,
        library_targets_test,
        dependency_name_test,
        is_clang_target_test,
        is_swift_target_test,
        get_target_test,
    )