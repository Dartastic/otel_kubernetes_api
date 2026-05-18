// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_kubernetes_api_suppression.dart';

const _tracerName = 'dartastic_otel_libs_kubernetes_api';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Kubernetes REST API call in a CLIENT span. [verb] is the
/// k8s verb (`get`, `list`, `watch`, `create`, `update`, `patch`,
/// `delete`, `deletecollection`, `proxy`); [kind] is the resource
/// kind (Pod, Deployment, etc.).
Future<T> tracedKubernetesApi<T>({
  required String verb,
  required String kind,
  required Future<T> Function() invoke,
  String? namespace,
  String? name,
  String? apiGroup,
  String? cluster,
}) async {
  if (kubernetesApiInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'rpc.system': 'kubernetes',
    'k8s.api.verb': verb,
    'k8s.api.kind': kind,
  };
  if (namespace != null) m['k8s.namespace.name'] = namespace;
  if (name != null) m['k8s.resource.name'] = name;
  if (apiGroup != null) m['k8s.api.group'] = apiGroup;
  if (cluster != null) m['k8s.cluster.name'] = cluster;

  final span = _tracer().startSpan(
    'k8s $verb $kind',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
