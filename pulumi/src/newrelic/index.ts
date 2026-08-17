import * as newrelic from "@pulumi/newrelic";
import * as pulumi from "@pulumi/pulumi";
import { Config } from "@/lib/config.ts";
import { claudeCodeOverview } from "./dashboards.ts";

const ingestKey = new newrelic.ApiAccessKey("ingest", {
  accountId: Config.newrelic.accountId,
  keyType: "INGEST",
  ingestType: "LICENSE",
  name: "otlp-ingest",
  notes: "Managed by Pulumi – OTLP telemetry ingestion",
});

const otlpEndpoint =
  Config.newrelic.region === "EU"
    ? "https://otlp.eu01.nr-data.net:4318"
    : "https://otlp.nr-data.net:4318";

export const registerNewrelic = (): {
  otlpEndpoint: string;
  newrelicLicenseKey: pulumi.Output<string>;
  dashboardGuid: pulumi.Output<string>;
} => ({
  otlpEndpoint,
  // provider が secret 扱いにしないため、stack output に出る前に明示的に包む
  newrelicLicenseKey: pulumi.secret(ingestKey.key),
  dashboardGuid: claudeCodeOverview.guid,
});
