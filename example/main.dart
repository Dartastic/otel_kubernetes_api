// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_kubernetes_api/otel_kubernetes_api.dart';

/// Traces Kubernetes calls with OpenTelemetry.
///
/// `otel_kubernetes_api` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Kubernetes call in
/// [tracedKubernetesApi]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'kubernetes-api-example');

  // Wraps a Kubernetes REST API call in a CLIENT span.
  final kubernetesApiId = await tracedKubernetesApi<String>(
    verb: 'get',
    kind: 'example',
    namespace: 'example',
    name: 'example',
    apiGroup: 'example',
    cluster: 'example',
    invoke: () async {
      // Make the Kubernetes call here, then report what it returned.
      return 'kubernetes_api_8f3a2c';
    },
  );
  OTelLog.info('tracedKubernetesApi returned $kubernetesApiId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutKubernetesApiInstrumentationAsync.
  await runWithoutKubernetesApiInstrumentationAsync(
    () => tracedKubernetesApi<String>(
      verb: 'get',
      kind: 'example',
      namespace: 'example',
      name: 'example',
      apiGroup: 'example',
      cluster: 'example',
      invoke: () async {
        return 'kubernetes_api_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
