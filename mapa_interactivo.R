# =============================================================================
# Cartografía interactiva con R: 10 sitios de Colombia (3 en Medellín)
# Autor: John Alejandro Pérez Pérez
# Curso: XRREGEN02 Revolución Geoespacial: los nuevos mapas (ITM)
# Docente: Sebastián Mejía Ríos
#
# Qué hace: crea un mapa dinámico con los paquetes sf (datos geográficos) y
# leaflet (mapa interactivo) y lo exporta como index.html para GitHub Pages.
# Funciona igual en RStudio y en Posit Cloud.
# Coordenadas: OpenStreetMap (Nominatim), consultadas el 28-oct-2026.
# =============================================================================

# --- 0. Paquetes --------------------------------------------------------------
# La primera vez hay que instalarlos (en Posit Cloud, una vez por proyecto):
# install.packages(c("sf", "leaflet", "htmlwidgets"))
library(sf)          # vectores geográficos (simple features)
library(leaflet)     # mapas web interactivos (Leaflet.js)
library(htmlwidgets) # exportar el mapa a HTML

# --- 1. Datos: una variable (vector) por columna -----------------------------
nombre <- c(
  "ITM, campus Robledo",
  "Pueblito Paisa (cerro Nutibara)",
  "Parque Arví",
  "Puerta del Reloj",
  "Cabo San Juan del Guía (PNN Tayrona)",
  "Caño Cristales",
  "Desierto de la Tatacoa",
  "Valle de Cocora",
  "Santuario de Las Lajas",
  "Leticia"
)
municipio <- c("Medellín", "Medellín", "Medellín", "Cartagena", "Santa Marta",
               "La Macarena", "Villavieja", "Salento", "Ipiales", "Leticia")
departamento <- c("Antioquia", "Antioquia", "Antioquia", "Bolívar", "Magdalena",
                  "Meta", "Huila", "Quindío", "Nariño", "Amazonas")
latitud <- c(6.274634, 6.236186, 6.281397, 10.423050, 11.338045,
             2.272213, 3.253609, 4.637941, 0.805604, -4.212921)
longitud <- c(-75.588775, -75.580280, -75.502688, -75.549212, -73.974462,
              -73.765464, -75.146771, -75.487051, -77.586008, -69.942596)
descripcion <- c(
  "Campus Robledo del Instituto Tecnológico Metropolitano, la institución donde estudio Ingeniería de la Calidad.",
  "Réplica de un pueblo antioqueño tradicional en la cima del cerro Nutibara, con vista panorámica de Medellín.",
  "Parque ecológico y arqueológico del corregimiento de Santa Elena; se llega en la línea L del Metrocable.",
  "Entrada principal del centro histórico amurallado de Cartagena, patrimonio de la humanidad (UNESCO).",
  "Playa del Parque Nacional Natural Tayrona, al pie de la Sierra Nevada de Santa Marta.",
  "Río de la serranía de La Macarena famoso por sus colores, que vienen de la planta acuática Macarenia clavigera.",
  "Bosque seco tropical de paisajes erosionados en el norte del Huila; muy buen sitio para observar estrellas.",
  "Valle del Quindío donde crece la palma de cera, el árbol nacional de Colombia.",
  "Basílica neogótica construida sobre el cañón del río Guáitara, cerca de la frontera con Ecuador.",
  "Capital del Amazonas, en la frontera con Brasil y Perú; el único sitio del mapa en el hemisferio sur."
)
grupo <- ifelse(municipio == "Medellín", "Medellín", "Resto de Colombia")

sitios <- data.frame(nombre, municipio, departamento, grupo, descripcion,
                     latitud, longitud)

# --- 2. De tabla a objeto espacial con sf ------------------------------------
# coords = c(x, y): primero la longitud y después la latitud.
# crs = 4326 es WGS 84, el sistema de coordenadas de los GPS.
sitios_sf <- st_as_sf(sitios, coords = c("longitud", "latitud"),
                      crs = 4326, remove = FALSE)
print(sitios_sf)
st_crs(sitios_sf)$input

# Un cálculo espacial con sf: distancia en línea recta de cada sitio al ITM.
itm <- sitios_sf[1, ]
sitios_sf$dist_itm_km <- round(as.numeric(st_distance(sitios_sf, itm)) / 1000, 1)

# --- 3. Estilo: colores y ventanas emergentes (popups) -----------------------
paleta <- colorFactor(palette = c("#C0392B", "#1F3864"),
                      domain = c("Medellín", "Resto de Colombia"))

sitios_sf$popup <- sprintf(
  "<div style='font-family:Arial;max-width:240px'>
     <b style='font-size:14px'>%s</b><br>
     %s, %s<br><br>%s<br><br>
     <b>Latitud:</b> %.6f<br><b>Longitud:</b> %.6f<br>
     <b>Distancia al ITM:</b> %s km
   </div>",
  sitios_sf$nombre, sitios_sf$municipio, sitios_sf$departamento,
  sitios_sf$descripcion, sitios_sf$latitud, sitios_sf$longitud,
  format(sitios_sf$dist_itm_km, big.mark = ".", decimal.mark = ",")
)

titulo <- "<div style='font-family:Arial;background:white;padding:8px 12px;
  border-radius:6px;box-shadow:0 1px 4px rgba(0,0,0,.3)'>
  <b style='font-size:15px;color:#1F3864'>Mis 10 sitios de Colombia</b><br>
  <span style='font-size:12px'>3 en Medellín y 7 en el resto del país ·
  John Alejandro Pérez Pérez · ITM</span></div>"

# --- 4. El mapa interactivo con leaflet --------------------------------------
medellin <- sitios_sf[sitios_sf$grupo == "Medellín", ]
resto    <- sitios_sf[sitios_sf$grupo == "Resto de Colombia", ]

mapa <- leaflet() %>%
  # Mapas base que el usuario puede cambiar
  addProviderTiles(providers$OpenStreetMap, group = "Calles (OpenStreetMap)") %>%
  addProviderTiles(providers$Esri.WorldImagery, group = "Satélite (Esri)") %>%
  addProviderTiles(providers$CartoDB.Positron, group = "Claro (CARTO)") %>%
  # Capas de puntos, una por grupo, para poder prenderlas y apagarlas
  addCircleMarkers(data = medellin, radius = 9, color = "white", weight = 2,
                   fillColor = ~paleta(grupo), fillOpacity = 0.95,
                   popup = ~popup, label = ~nombre, group = "Medellín") %>%
  addCircleMarkers(data = resto, radius = 9, color = "white", weight = 2,
                   fillColor = ~paleta(grupo), fillOpacity = 0.95,
                   popup = ~popup, label = ~nombre, group = "Resto de Colombia") %>%
  addLegend(position = "bottomright", pal = paleta, values = sitios_sf$grupo,
            title = "Sitios", opacity = 1) %>%
  addLayersControl(
    baseGroups = c("Calles (OpenStreetMap)", "Satélite (Esri)", "Claro (CARTO)"),
    overlayGroups = c("Medellín", "Resto de Colombia"),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  addScaleBar(position = "bottomleft",
              options = scaleBarOptions(imperial = FALSE)) %>%
  addMiniMap(toggleDisplay = TRUE, position = "bottomright") %>%
  # Botones para saltar a Medellín o volver a toda Colombia
  addEasyButton(easyButton(
    icon = "fa-building", title = "Ver Medellín",
    onClick = JS("function(btn, map){ map.setView([6.262, -75.56], 12); }"))) %>%
  addEasyButton(easyButton(
    icon = "fa-globe", title = "Ver toda Colombia",
    onClick = JS("function(btn, map){ map.fitBounds([[-4.5, -79.5], [12.6, -66.8]]); }"))) %>%
  addControl(html = titulo, position = "topright") %>%
  fitBounds(lng1 = -79.5, lat1 = -4.5, lng2 = -66.8, lat2 = 12.6)

mapa  # se ve en el panel Viewer de RStudio o Posit Cloud

# --- 5. Exportar a HTML ------------------------------------------------------
# selfcontained = TRUE mete todo (código y estilos) en un solo archivo.
# Se llama index.html para que GitHub Pages lo abra como página principal.
saveWidget(mapa, file = "index.html", selfcontained = TRUE,
           title = "Mis 10 sitios de Colombia | John Alejandro Pérez Pérez")

# --- 6. Publicar en GitHub Pages (resumen) -----------------------------------
# 1) Crear un repositorio público en GitHub (por ejemplo, mapa-interactivo-colombia).
# 2) Subir index.html (y este script) con «Add file > Upload files».
# 3) Settings > Pages > Source: «Deploy from a branch», rama main, carpeta / (root).
# 4) Esperar uno o dos minutos y abrir https://<usuario>.github.io/mapa-interactivo-colombia/
