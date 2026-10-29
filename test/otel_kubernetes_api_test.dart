// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_kubernetes_api/otel_kubernetes_api.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_kubernetes_api-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('get Pod records CLIENT span', () async {
    await tracedKubernetesApi<String>(
      verb: 'get',
      kind: 'Pod',
      namespace: 'default',
      name: 'app-1',
      cluster: 'prod-us',
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('k8s get Pod')!);
    expect(a['rpc.system'], 'kubernetes');
    expect(a['k8s.api.verb'], 'get');
    expect(a['k8s.api.kind'], 'Pod');
    expect(a['k8s.namespace.name'], 'default');
    expect(a['k8s.resource.name'], 'app-1');
    expect(a['k8s.cluster.name'], 'prod-us');
  });

  test('suppression skips spans', () async {
    await runWithoutKubernetesApiInstrumentationAsync(() async {
      await tracedKubernetesApi<String>(
        verb: 'list',
        kind: 'Service',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('k8s '), isEmpty);
  });
}
