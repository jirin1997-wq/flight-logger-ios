import SwiftUI

/// The multifunction page, built for the iPad.
///
/// Beside the moving map sit the Direct-to target, the nearest fields and the
/// field's schematic. The schematic says plainly what it lacks: taxiways and
/// aprons are not in the bundled data yet, so the screen does not draw them.
struct MFDView: View {

    @EnvironmentObject private var recorder: FlightRecorder
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var tiles: TileStore
    @Environment(\.dismiss) private var dismiss

    @State private var follow = true
    @State private var zoomSpan: Double = 0.04

    /// Read once: the bundled schematics do not change while the app runs.
    private static let library: [AirportDiagram] = AirportDiagrams.load()

    /// The field the page is about: the Direct-to target, else the nearest field.
    private var fieldCode: String? {
        recorder.directTarget?.code ?? recorder.nearestAirport?.code
    }

    private var diagram: AirportDiagram? {
        AirportDiagrams.diagram(for: fieldCode, in: Self.library)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            HStack(spacing: 0) {
                mapPane
                sidePane
                    .frame(width: 340)
            }
            keyRow
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Header

    private var header: some View {
        let speed: Double? = recorder.snapshot.speed >= 0 ? recorder.snapshot.speed : nil
        return HStack(spacing: 14) {
            Text("MFD")
                .font(.title2.weight(.heavy))
            Text(fieldCode ?? "—")
                .font(.title3.weight(.semibold))
            Spacer()
            Text(Units.knotsLabel(speed))
                .font(.title3.monospacedDigit())
            Text(Units.feetLabel(recorder.snapshot.agl))
                .font(.title3.monospacedDigit())
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Map

    private var mapPane: some View {
        TileMapView(
            track: recorder.liveTrack.points,
            source: settings.tileSource,
            files: tiles.files,
            allowsNetwork: settings.downloadTilesWhileBrowsing,
            follow: follow,
            departure: recorder.currentFlight?.takeoff.coordinate,
            arrival: nil,
            marked: nil,
            staticRegion: nil,
            target: recorder.directTarget?.coordinate,
            aircraft: recorder.position,
            diagram: diagram,
            zoomSpan: zoomSpan
        )
        .overlay(alignment: .bottomLeading) {
            MapAttribution(source: settings.tileSource)
                .padding(8)
        }
    }

    // MARK: - Side panel

    private var sidePane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                directCard
                nearestCard
                diagramCard
                Text(L10n.t("Schéma je zjednodušené a nezobrazuje všechny prvky letiště. Pro navigaci na zemi používej oficiální mapy letiště."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .background(Color(.secondarySystemBackground))
    }

    private var directCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let target = recorder.directTarget, let nav = recorder.directNavigation {
                Text(target.code)
                    .font(.title2.bold())
                Text(target.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(L10n.t("Kurz")) \(String(format: "%03.0f°", nav.bearing))  ·  \(String(format: "%.1f NM", nav.distance / 1852))")
                    .font(.headline.monospacedDigit())
            } else {
                Text(L10n.t("Cíl není zvolen"))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var nearestCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("Nejbližší plochy"))
                .font(.subheadline.weight(.semibold))
            ForEach(recorder.nearbyAirfields(limit: 6)) { item in
                Button {
                    recorder.setDirectTarget(item.airport)
                } label: {
                    HStack {
                        Text(item.airport.code)
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%03.0f°", item.bearing))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f NM", item.distance / 1852))
                            .font(.subheadline.monospacedDigit())
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var diagramCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let diagram {
                Text("\(diagram.code) · \(diagram.name)")
                    .font(.subheadline.weight(.semibold))
                Text(L10n.t("Dráhy") + ": " + diagram.runways.map(\.designator).joined(separator: ", "))
                    .font(.callout)
                if diagram.taxiways.isEmpty && diagram.aprons.isEmpty {
                    Text(L10n.t("Pojezdové dráhy a aprony nejsou v datech — na mapě nejsou."))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Text(L10n.t("Schéma: zdroj") + ": " + diagram.source)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text(L10n.t("Schéma pro toto letiště není."))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Keys

    private var keyRow: some View {
        HStack(spacing: 8) {
            key(L10n.t("Zpět"), tint: .gray) { dismiss() }
            key(L10n.t("Oddálit"), tint: .blue) { zoomSpan = min(0.5, zoomSpan * 2) }
            key(L10n.t("Přiblížit"), tint: .blue) { zoomSpan = max(0.004, zoomSpan / 2) }
            key(follow ? L10n.t("Sledování zapnuto") : L10n.t("Sledovat"), tint: .green) { follow.toggle() }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func key(_ title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundStyle(tint)
                .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
