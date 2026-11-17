<#
  Construye el proyecto Enterprise Architect (.eapx) con los modelos UML recuperados
  por ingenieria inversa del proyecto Java "AbstractFactoryReverseExample".

  Usa la API de automatizacion COM de Sparx Systems Enterprise Architect (EA.Repository).
  Todos los elementos, conectores y diagramas se crean como elementos UML nativos.

  Uso:  powershell -ExecutionPolicy Bypass -File build_eap_model.ps1 [-OutFile <ruta.eapx>] [-PreviewDir <carpeta>]
#>
param(
  [string]$OutFile = (Join-Path $PSScriptRoot "AbstractFactoryReverseExample.eapx"),
  [string]$PreviewDir = ""
)

$ErrorActionPreference = 'Stop'

if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

$repo = New-Object -ComObject EA.Repository
if (-not $repo.CreateModel(0, $OutFile, 0)) { throw "No se pudo crear el modelo: $($repo.GetLastError())" }
if (-not $repo.OpenFile($OutFile))        { throw "No se pudo abrir el modelo: $($repo.GetLastError())" }

# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------
function Add-Package($parent, [string]$name, [string]$notes = "") {
  $p = $parent.Packages.AddNew($name, "Package")
  $p.Notes = $notes
  [void]$p.Update()
  $parent.Packages.Refresh()
  return $p
}

function Add-Tag($el, [string]$name, [string]$value) {
  $t = $el.TaggedValues.AddNew($name, $value)
  [void]$t.Update()
}

function Add-Element($pkg, [string]$name, [string]$type, [hashtable]$opt = @{}) {
  $e = $pkg.Elements.AddNew($name, $type)
  if ($opt.Stereotype) { $e.Stereotype = $opt.Stereotype }
  if ($opt.Notes)      { $e.Notes = $opt.Notes }
  if ($opt.Abstract)   { $e.Abstract = "1" }
  if ($opt.Visibility) { $e.Visibility = $opt.Visibility }
  if ($opt.Language)   { $e.Gentype = $opt.Language }
  if ($opt.ContainsKey('Subtype')) { $e.Subtype = $opt.Subtype }
  if ($opt.Classifier) { $e.ClassifierID = $opt.Classifier.ElementID }
  [void]$e.Update()
  if ($opt.Source) { Add-Tag $e "codigo_fuente" $opt.Source }
  $pkg.Elements.Refresh()
  return $e
}

function Add-Attr($el, [string]$name, [string]$type, [string]$vis, [hashtable]$opt = @{}) {
  $a = $el.Attributes.AddNew($name, $type)
  $a.Visibility = $vis
  if ($opt.Static)  { $a.IsStatic = $true }
  if ($opt.Const)   { $a.IsConst  = $true }
  if ($opt.Default) { $a.Default  = $opt.Default }
  if ($opt.Classifier) { $a.ClassifierID = $opt.Classifier.ElementID }
  if ($opt.Notes)   { $a.Notes = $opt.Notes }
  [void]$a.Update()
  $el.Attributes.Refresh()
  return $a
}

# $params: arreglo de "nombre:Tipo"
function Add-Op($el, [string]$name, [string]$ret, [string]$vis, [string[]]$params = @(), [hashtable]$opt = @{}) {
  $m = $el.Methods.AddNew($name, $ret)
  $m.Visibility = $vis
  if ($opt.Static)   { $m.IsStatic = $true }
  if ($opt.Abstract) { $m.Abstract = $true }
  if ($opt.Stereotype) { $m.Stereotype = $opt.Stereotype }
  if ($opt.Notes)    { $m.Notes = $opt.Notes }
  [void]$m.Update()
  $pos = 0
  foreach ($p in $params) {
    $pn, $pt = $p.Split(':')
    $prm = $m.Parameters.AddNew($pn, $pt)
    $prm.Kind = "in"
    $prm.Position = $pos++
    [void]$prm.Update()
  }
  $m.Parameters.Refresh()
  $el.Methods.Refresh()
  return $m
}

function Add-Conn($src, $dst, [string]$type, [hashtable]$opt = @{}) {
  $c = $src.Connectors.AddNew($(if ($opt.Name) { $opt.Name } else { "" }), $type)
  $c.SupplierID = $dst.ElementID
  if ($opt.Stereotype) { $c.Stereotype = $opt.Stereotype }
  if ($opt.Subtype)    { $c.Subtype = $opt.Subtype }
  if ($opt.Notes)      { $c.Notes = $opt.Notes }
  if ($opt.Direction)  { $c.Direction = $opt.Direction }
  [void]$c.Update()
  if ($opt.SupplierRole -or $opt.SupplierCard -or $opt.SupplierNav) {
    $se = $c.SupplierEnd
    if ($opt.SupplierRole) { $se.Role = $opt.SupplierRole }
    if ($opt.SupplierCard) { $se.Cardinality = $opt.SupplierCard }
    if ($opt.SupplierVis)  { $se.Visibility = $opt.SupplierVis }
    if ($opt.SupplierNav)  { $se.Navigable = $opt.SupplierNav }
    [void]$se.Update()
  }
  if ($opt.ClientCard -or $opt.ClientNav) {
    $ce = $c.ClientEnd
    if ($opt.ClientCard) { $ce.Cardinality = $opt.ClientCard }
    if ($opt.ClientNav)  { $ce.Navigable = $opt.ClientNav }
    [void]$ce.Update()
  }
  [void]$c.Update()
  $src.Connectors.Refresh()
  return $c
}

function Add-DiagramObj($diag, $el, [int]$l, [int]$t, [int]$w, [int]$h, [int]$seq = 0) {
  $r = $l + $w; $b = $t + $h
  $o = $diag.DiagramObjects.AddNew("l=$l;r=$r;t=$t;b=$b;", "")
  $o.ElementID = $el.ElementID
  if ($seq -gt 0) { $o.Sequence = $seq }
  [void]$o.Update()
  return $o
}

function New-Diagram($pkg, [string]$name, [string]$type, [string]$notes) {
  $d = $pkg.Diagrams.AddNew($name, $type)
  $d.Notes = $notes
  [void]$d.Update()
  $pkg.Diagrams.Refresh()
  return $d
}

# Tamano aproximado de una caja de clase segun su contenido.
function Get-ClassSize($el, [int]$minW = 160) {
  $lines = @($el.Name)
  if ($el.Stereotype) { $lines += "<<$($el.Stereotype)>>" }
  $nA = 0; $nO = 0
  foreach ($a in $el.Attributes) {
    $nA++
    $txt = "+ $($a.Name): $($a.Type)"; if ($a.Default) { $txt += " = $($a.Default)" }
    $lines += $txt
  }
  foreach ($m in $el.Methods) {
    $nO++
    $ps = @(); foreach ($p in $m.Parameters) { $ps += "$($p.Name): $($p.Type)" }
    $lines += "+ $($m.Name)($($ps -join ', ')): $($m.ReturnType)"
  }
  $maxLen = ($lines | Measure-Object -Property Length -Maximum).Maximum
  $w = [Math]::Max($minW, [int]($maxLen * 6.6) + 24)
  $hdr = if ($el.Stereotype) { 2 } else { 1 }
  $h = 18 + 15 * $hdr + 15 * $nA + 15 * $nO + 18
  if ($nA -gt 0) { $h += 6 }; if ($nO -gt 0) { $h += 6 }
  return @($w, $h)
}

function Place-Class($diag, $el, [int]$l, [int]$t, [int]$minW = 160) {
  $sz = Get-ClassSize $el $minW
  [void](Add-DiagramObj $diag $el $l $t $sz[0] $sz[1])
}

# ---------------------------------------------------------------------------
# Estructura de paquetes
# ---------------------------------------------------------------------------
$root = $repo.Models.GetAt(0)
$root.Name = "AbstractFactoryReverseExample - Ingenieria inversa"
$root.Notes = "Modelo UML recuperado por ingenieria inversa del proyecto Java AbstractFactoryReverseExample (IntelliJ IDEA, paquete por defecto, Java SE + Swing). Patron principal: Abstract Factory."
[void]$root.Update()

$pkgFunc  = Add-Package $root "01 Modelo funcional"        "Casos de uso recuperados del comportamiento de la GUI (AutoSearchUI / ButtonHandler)."
$pkgStruc = Add-Package $root "02 Modelo estructural"      "Clases, interfaces y relaciones recuperadas del codigo fuente."
$pkgBeh   = Add-Package $root "03 Modelo de comportamiento" "Diagramas de secuencia de los flujos principales."

$pkgApp = Add-Package $pkgStruc "Aplicacion (paquete por defecto)" "Clases del proyecto. Todos los archivos .java estan en el paquete por defecto (sin sentencia package)."
$pkgLib = Add-Package $pkgStruc "Bibliotecas externas (Java SE)" "Tipos de la biblioteca estandar de Java referenciados por el proyecto. No forman parte del codigo del proyecto; se modelan solo como referencia (sin miembros)."

# ---------------------------------------------------------------------------
# MODELO ESTRUCTURAL
# ---------------------------------------------------------------------------
$J = @{ Language = "Java" }

# --- Tipos externos (Java SE) ---
$xJFrame    = Add-Element $pkgLib "JFrame"         "Class"     @{ Notes = "javax.swing.JFrame (externa)."; Language = "Java" }
$xJComboBox = Add-Element $pkgLib "JComboBox"      "Class"     @{ Notes = "javax.swing.JComboBox (externa). Usada como tipo crudo (raw type) en el proyecto."; Language = "Java" }
$xJLabel    = Add-Element $pkgLib "JLabel"         "Class"     @{ Notes = "javax.swing.JLabel (externa)."; Language = "Java" }
$xJButton   = Add-Element $pkgLib "JButton"        "Class"     @{ Notes = "javax.swing.JButton (externa). Instancias locales del constructor de AutoSearchUI."; Language = "Java" }
$xListener  = Add-Element $pkgLib "ActionListener" "Interface" @{ Notes = "java.awt.event.ActionListener (externa)."; Language = "Java" }
$xActEvent  = Add-Element $pkgLib "ActionEvent"    "Class"     @{ Notes = "java.awt.event.ActionEvent (externa)."; Language = "Java" }
$xWinAdapt  = Add-Element $pkgLib "WindowAdapter"  "Class"     @{ Notes = "java.awt.event.WindowAdapter (externa)."; Language = "Java"; Abstract = $true }
$xWinEvent  = Add-Element $pkgLib "WindowEvent"    "Class"     @{ Notes = "java.awt.event.WindowEvent (externa)."; Language = "Java" }
$xSystem    = Add-Element $pkgLib "System"         "Class"     @{ Notes = "java.lang.System (externa). Se invoca System.exit(int) para terminar la aplicacion."; Language = "Java" }

# --- Productos abstractos ---
$cLuxury = Add-Element $pkgApp "Luxury" "Interface" @{ Language = "Java"; Source = "Luxury.java";
  Notes = "Patron Abstract Factory: PRODUCTO ABSTRACTO A. Interfaz de los vehiculos de lujo." }
[void](Add-Op $cLuxury "getLuxuryName"     "String" "Public" @() @{ Abstract = $true })
[void](Add-Op $cLuxury "getLuxuryFeatures" "String" "Public" @() @{ Abstract = $true })

$cNonLuxury = Add-Element $pkgApp "NonLuxury" "Interface" @{ Language = "Java"; Source = "NonLuxury.java";
  Notes = "Patron Abstract Factory: PRODUCTO ABSTRACTO B. Interfaz de los vehiculos no lujosos." }
[void](Add-Op $cNonLuxury "getNLName"     "String" "Public" @() @{ Abstract = $true })
[void](Add-Op $cNonLuxury "getNLFeatures" "String" "Public" @() @{ Abstract = $true })

# --- Productos concretos ---
function New-Product($name, $iface, $ctorParam, $nameOp, $featOp, $featValue, $file) {
  $c = Add-Element $pkgApp $name "Class" @{ Language = "Java"; Source = $file;
    Notes = "Patron Abstract Factory: PRODUCTO CONCRETO. Implementa $($iface.Name). $featOp() devuelve la cadena constante '$featValue'." }
  [void](Add-Attr $c "name" "String" "Private")
  [void](Add-Op $c $name "" "Public" @("$($ctorParam):String") @{ Stereotype = "constructor" })
  [void](Add-Op $c $nameOp "String" "Public")
  [void](Add-Op $c $featOp "String" "Public")
  [void](Add-Conn $c $iface "Realisation")
  return $c
}
$cLuxuryCAR    = New-Product "LuxuryCAR"    $cLuxury    "cName" "getLuxuryName" "getLuxuryFeatures" "Luxury Car Features "     "LuxuryCAR.java"
$cLuxurySUV    = New-Product "LuxurySUV"    $cLuxury    "sName" "getLuxuryName" "getLuxuryFeatures" "Luxury SUV Features "     "LuxurySUV.java"
$cNonLuxuryCAR = New-Product "NonLuxuryCAR" $cNonLuxury "sName" "getNLName"     "getNLFeatures"     "Non-Luxury CAR Features " "NonLuxuryCAR.java"
$cNonLuxurySUV = New-Product "NonLuxurySUV" $cNonLuxury "sName" "getNLName"     "getNLFeatures"     "Non-Luxury SUV Features " "NonLuxurySUV.java"
$cLuxuryBYC    = New-Product "LuxuryBYCICLE"    $cLuxury    "cName" "getLuxuryName" "getLuxuryFeatures" "Luxury Bycicle Features "     "LuxuryBYCICLE.java"
$cNonLuxuryBYC = New-Product "NonLuxuryBYCICLE" $cNonLuxury "sName" "getNLName"     "getNLFeatures"     "Non-Luxury BYCICLE Features " "NonLuxuryBYCICLE.java"

# --- Fabrica abstracta ---
$cVF = Add-Element $pkgApp "VehicleFactory" "Class" @{ Language = "Java"; Abstract = $true; Source = "VehicleFactory.java";
  Notes = "Patron Abstract Factory: FABRICA ABSTRACTA. Declara los metodos de creacion de la familia de productos (Luxury, NonLuxury). Incluye el metodo estatico getVehicleFactory(type), que actua como selector (fabrica simple) de la fabrica concreta: devuelve SUVVehicleFactory si type = SUV, BYCICLEVehicleFactory si type = BYCICLE, y CARVehicleFactory si type = CAR o cualquier otro valor (valor por defecto)." }
[void](Add-Attr $cVF "CAR" "String" "Public" @{ Static = $true; Const = $true; Default = '"Car"' })
[void](Add-Attr $cVF "SUV" "String" "Public" @{ Static = $true; Const = $true; Default = '"Suv"' })
[void](Add-Attr $cVF "BYCICLE" "String" "Public" @{ Static = $true; Const = $true; Default = '"Bycicle"'; Notes = "Agregada para el nuevo tipo de vehiculo. Nota: el identificador esta escrito BYCICLE (no el ingles BICYCLE) tal como aparece en el codigo." })
[void](Add-Op $cVF "getLuxury"    "Luxury"    "Public" @() @{ Abstract = $true })
[void](Add-Op $cVF "getNonLuxury" "NonLuxury" "Public" @() @{ Abstract = $true })
[void](Add-Op $cVF "getVehicleFactory" "VehicleFactory" "Public" @("type:String") @{ Static = $true;
  Notes = "if (type.equals(CAR)) return new CARVehicleFactory(); if (type.equals(SUV)) return new SUVVehicleFactory(); if (type.equals(BYCICLE)) return new BYCICLEVehicleFactory(); return new CARVehicleFactory();" })

# --- Fabricas concretas ---
$cCARVF = Add-Element $pkgApp "CARVehicleFactory" "Class" @{ Language = "Java"; Source = "CARVehicleFactory.java";
  Notes = "Patron Abstract Factory: FABRICA CONCRETA de la variante Car. Redefine getLuxury()/getNonLuxury() con tipos de retorno covariantes (LuxuryCAR / NonLuxuryCAR); el compilador genera metodos puente que devuelven Luxury / NonLuxury." }
[void](Add-Op $cCARVF "getLuxury"    "LuxuryCAR"    "Public" @() @{ Notes = 'return new LuxuryCAR("Luxury-Car");' })
[void](Add-Op $cCARVF "getNonLuxury" "NonLuxuryCAR" "Public" @() @{ Notes = 'return new NonLuxuryCAR("NonLuxuryL-Car");  (la "L" adicional esta en el codigo original)' })

$cSUVVF = Add-Element $pkgApp "SUVVehicleFactory" "Class" @{ Language = "Java"; Source = "SUVVehicleFactory.java";
  Notes = "Patron Abstract Factory: FABRICA CONCRETA de la variante SUV. Redefine getLuxury()/getNonLuxury() con tipos de retorno covariantes (LuxurySUV / NonLuxurySUV)." }
[void](Add-Op $cSUVVF "getLuxury"    "LuxurySUV"    "Public" @() @{ Notes = 'return new LuxurySUV("Luxury-SUV");' })
[void](Add-Op $cSUVVF "getNonLuxury" "NonLuxurySUV" "Public" @() @{ Notes = 'return new NonLuxurySUV("Non-Luxury-SUV");' })

$cBYCVF = Add-Element $pkgApp "BYCICLEVehicleFactory" "Class" @{ Language = "Java"; Source = "BYCICLEVehicleFactory.java";
  Notes = "Patron Abstract Factory: FABRICA CONCRETA de la variante Bycicle (agregada). Redefine getLuxury()/getNonLuxury() con tipos de retorno covariantes (LuxuryBYCICLE / NonLuxuryBYCICLE)." }
[void](Add-Op $cBYCVF "getLuxury"    "LuxuryBYCICLE"    "Public" @() @{ Notes = 'return new LuxuryBYCICLE("Luxury-Bycicle");' })
[void](Add-Op $cBYCVF "getNonLuxury" "NonLuxuryBYCICLE" "Public" @() @{ Notes = 'return new NonLuxuryBYCICLE("NonLuxuryL-Bycicle");  (arrastra la misma rareza "NonLuxuryL-" del codigo original)' })

# --- Cliente / interfaz grafica ---
$cUI = Add-Element $pkgApp "AutoSearchUI" "Class" @{ Language = "Java"; Source = "AutoSearchUI.java";
  Notes = "Ventana Swing (JFrame) de la aplicacion y punto de entrada (main). Patron Abstract Factory: parte del CLIENTE (presenta las opciones y muestra el resultado)." }
[void](Add-Attr $cUI "newline"    "String" "Public" @{ Static = $true; Const = $true; Default = '"\n"'; Notes = "Declarada pero no utilizada en el codigo." })
[void](Add-Attr $cUI "SEARCH"     "String" "Public" @{ Static = $true; Const = $true; Default = '"Search"' })
[void](Add-Attr $cUI "EXIT"       "String" "Public" @{ Static = $true; Const = $true; Default = '"Exit"' })
[void](Add-Attr $cUI "LUXURY"     "String" "Public" @{ Static = $true; Const = $true; Default = '"Luxury"' })
[void](Add-Attr $cUI "NON_LUXURY" "String" "Public" @{ Static = $true; Const = $true; Default = '"Non-Luxury"' })
[void](Add-Attr $cUI "cmbVehicleCategory" "JComboBox" "Private" @{ Classifier = $xJComboBox })
[void](Add-Attr $cUI "cmbVehicleType"     "JComboBox" "Private" @{ Classifier = $xJComboBox })
[void](Add-Attr $cUI "lblVehicleCategory" "JLabel" "Private" @{ Classifier = $xJLabel })
[void](Add-Attr $cUI "lblVehicleType"     "JLabel" "Private" @{ Classifier = $xJLabel })
[void](Add-Attr $cUI "lblCarName"         "JLabel" "Private" @{ Classifier = $xJLabel })
[void](Add-Attr $cUI "lblCarNameValue"    "JLabel" "Private" @{ Classifier = $xJLabel })
[void](Add-Op $cUI "AutoSearchUI" "" "Public" @() @{ Stereotype = "constructor"; Notes = "Construye los combos, etiquetas y botones, registra los ButtonHandler y organiza el panel con GridBagLayout." })
[void](Add-Op $cUI "main" "void" "Public" @("args:String[]") @{ Static = $true })
[void](Add-Op $cUI "getSelectedCategory" "String" "Public")
[void](Add-Op $cUI "getSelectedType"     "String" "Public")
[void](Add-Op $cUI "setResult" "void" "Public" @("searchResult:String"))

$cAnon = Add-Element $pkgApp 'AutoSearchUI$1' "Class" @{ Language = "Java"; Stereotype = "anonymous"; Source = 'AutoSearchUI.java (main) -> AutoSearchUI$1.class';
  Notes = 'Clase anonima creada en AutoSearchUI.main: new WindowAdapter() { windowClosing(...) { System.exit(0); } }. El nombre AutoSearchUI$1 es el que genera el compilador.' }
[void](Add-Op $cAnon "windowClosing" "void" "Public" @("e:WindowEvent"))

$cBH = Add-Element $pkgApp "ButtonHandler" "Class" @{ Language = "Java"; Visibility = "Package"; Source = "AutoSearchUI.java (clase de nivel superior no publica)";
  Notes = "Manejador de eventos de los botones. Patron Abstract Factory: CLIENTE. Solo depende de VehicleFactory, Luxury y NonLuxury (abstracciones). Ademas emula un controlador: lee la seleccion de la vista, invoca la fabrica y devuelve el resultado a la vista." }
[void](Add-Attr $cBH "objAutoSearchUI" "AutoSearchUI" "Package" @{ Classifier = $cUI; Notes = "Queda en null cuando se usa el constructor sin argumentos (manejador del boton Exit)." })
[void](Add-Op $cBH "actionPerformed" "void" "Public" @("e:ActionEvent"))
[void](Add-Op $cBH "ButtonHandler" "" "Public" @() @{ Stereotype = "constructor" })
[void](Add-Op $cBH "ButtonHandler" "" "Public" @("inObjAutoSearchUI:AutoSearchUI") @{ Stereotype = "constructor" })

# --- Relaciones estructurales ---
[void](Add-Conn $cUI   $xJFrame   "Generalization")
[void](Add-Conn $cAnon $xWinAdapt "Generalization")
[void](Add-Conn $cBH   $xListener "Realisation")
[void](Add-Conn $cCARVF $cVF "Generalization")
[void](Add-Conn $cSUVVF $cVF "Generalization")
[void](Add-Conn $cBYCVF $cVF "Generalization")

# Asociacion: el atributo objAutoSearchUI es el extremo de la asociacion (no se repite en la caja de la clase).
$assoc = Add-Conn $cBH $cUI "Association" @{ Direction = "Source -> Destination"; SupplierRole = "objAutoSearchUI"; SupplierCard = "0..1"; SupplierVis = "Package"; SupplierNav = "Navigable"; ClientCard = "*"; ClientNav = "Non-Navigable";
  Notes = "ButtonHandler.objAutoSearchUI. Multiplicidad 0..1 porque el constructor ButtonHandler() no la inicializa (null). AutoSearchUI no guarda referencia a sus manejadores (*), solo los registra como listeners de los botones." }
# Se elimina el atributo duplicado para que la propiedad quede representada solo por el extremo de la asociacion.
for ($i = 0; $i -lt $cBH.Attributes.Count; $i++) { if ($cBH.Attributes.GetAt($i).Name -eq "objAutoSearchUI") { $cBH.Attributes.DeleteAt($i, $true); break } }
$cBH.Attributes.Refresh()

$depUIcreatesBH = Add-Conn $cUI $cBH "Dependency" @{ Stereotype = "create"; Notes = "AutoSearchUI() crea new ButtonHandler(this) y new ButtonHandler()." }
[void](Add-Conn $cUI $cAnon "Dependency" @{ Stereotype = "create"; Notes = 'main() crea la clase anonima AutoSearchUI$1 y la registra con addWindowListener.' })
[void](Add-Conn $cUI $cVF "Dependency" @{ Stereotype = "use"; Notes = "El constructor usa VehicleFactory.CAR, VehicleFactory.SUV y VehicleFactory.BYCICLE para llenar cmbVehicleType." })
[void](Add-Conn $cBH $cVF "Dependency" @{ Stereotype = "use"; Notes = "actionPerformed: VehicleFactory.getVehicleFactory(vhType), vf.getLuxury(), vf.getNonLuxury()." })
[void](Add-Conn $cBH $cLuxury "Dependency" @{ Stereotype = "use"; Notes = "Variable local Luxury c = vf.getLuxury(); c.getLuxuryName(); c.getLuxuryFeatures()." })
[void](Add-Conn $cBH $cNonLuxury "Dependency" @{ Stereotype = "use"; Notes = "Variable local NonLuxury s = vf.getNonLuxury(); s.getNLName(); s.getNLFeatures()." })
$depVFcar = Add-Conn $cVF $cCARVF "Dependency" @{ Stereotype = "create"; Notes = "getVehicleFactory(): new CARVehicleFactory(). La fabrica abstracta conoce a sus subclases (dependencia ciclica)." }
$depVFsuv = Add-Conn $cVF $cSUVVF "Dependency" @{ Stereotype = "create"; Notes = "getVehicleFactory(): new SUVVehicleFactory()." }
$depVFbyc = Add-Conn $cVF $cBYCVF "Dependency" @{ Stereotype = "create"; Notes = "getVehicleFactory(): new BYCICLEVehicleFactory()." }
[void](Add-Conn $cCARVF $cLuxuryCAR    "Dependency" @{ Stereotype = "create"; Notes = 'new LuxuryCAR("Luxury-Car")' })
[void](Add-Conn $cCARVF $cNonLuxuryCAR "Dependency" @{ Stereotype = "create"; Notes = 'new NonLuxuryCAR("NonLuxuryL-Car")' })
[void](Add-Conn $cSUVVF $cLuxurySUV    "Dependency" @{ Stereotype = "create"; Notes = 'new LuxurySUV("Luxury-SUV")' })
[void](Add-Conn $cSUVVF $cNonLuxurySUV "Dependency" @{ Stereotype = "create"; Notes = 'new NonLuxurySUV("Non-Luxury-SUV")' })
[void](Add-Conn $cBYCVF $cLuxuryBYC    "Dependency" @{ Stereotype = "create"; Notes = 'new LuxuryBYCICLE("Luxury-Bycicle")' })
[void](Add-Conn $cBYCVF $cNonLuxuryBYC "Dependency" @{ Stereotype = "create"; Notes = 'new NonLuxuryBYCICLE("NonLuxuryL-Bycicle")' })

# --- Diagrama de clases ---
$dClass = New-Diagram $pkgStruc "DC01 - Diagrama de clases (patron Abstract Factory)" "Logical" "Estructura completa del proyecto. Participantes del patron Abstract Factory: fabrica abstracta VehicleFactory; fabricas concretas CARVehicleFactory, SUVVehicleFactory y BYCICLEVehicleFactory; productos abstractos Luxury y NonLuxury; productos concretos LuxuryCAR, LuxurySUV, LuxuryBYCICLE, NonLuxuryCAR, NonLuxurySUV y NonLuxuryBYCICLE; cliente ButtonHandler (con la vista AutoSearchUI)."

Place-Class $dClass $xJFrame     40   20 120
Place-Class $dClass $cUI         20  110
Place-Class $dClass $cAnon       40  520
Place-Class $dClass $xWinAdapt   40  660 140
Place-Class $dClass $cBH        400  560
Place-Class $dClass $xListener  440  730 150
Place-Class $dClass $cVF        620  110
Place-Class $dClass $cCARVF     680  360
Place-Class $dClass $cSUVVF    1010  360
Place-Class $dClass $cBYCVF    1340  360
Place-Class $dClass $cLuxuryCAR    700  560 200
Place-Class $dClass $cNonLuxuryCAR 930  560 200
Place-Class $dClass $cLuxurySUV   1160  560 200
Place-Class $dClass $cNonLuxurySUV 1390 560 200
Place-Class $dClass $cLuxuryBYC   1620  560 210
Place-Class $dClass $cNonLuxuryBYC 1860 560 210
Place-Class $dClass $cLuxury    1060  780 200
Place-Class $dClass $cNonLuxury 1520  780 210

$nAF = Add-Element $pkgStruc "" "Note" @{ Notes = "Patron Abstract Factory`r`n- Fabrica abstracta: VehicleFactory`r`n- Fabricas concretas: CARVehicleFactory, SUVVehicleFactory, BYCICLEVehicleFactory`r`n- Productos abstractos: Luxury, NonLuxury`r`n- Productos concretos: LuxuryCAR, LuxurySUV, LuxuryBYCICLE, NonLuxuryCAR, NonLuxurySUV, NonLuxuryBYCICLE`r`n- Cliente: ButtonHandler (invocado por la vista AutoSearchUI)`r`n`r`nVehicleFactory.getVehicleFactory(type) es un metodo estatico que elige la fabrica concreta; por defecto devuelve CARVehicleFactory." }
[void](Add-DiagramObj $dClass $nAF 1030 60 360 180)
$nBH = Add-Element $pkgStruc "" "Note" @{ Notes = "El boton Exit se registra con new ButtonHandler(): objAutoSearchUI queda en null. Funciona solo porque la rama EXIT llama a System.exit(1) antes de usar la vista." }
[void](Add-DiagramObj $dClass $nBH 40 790 300 70)
[void](Add-Conn $nBH $cBH "NoteLink")
$dClass.Update() | Out-Null

# ---------------------------------------------------------------------------
# MODELO FUNCIONAL - Casos de uso
# ---------------------------------------------------------------------------
$actUser = Add-Element $pkgFunc "Usuario" "Actor" @{ Notes = "Persona que opera la ventana 'Abstract Factory - Example'. Es el unico actor: el sistema no se comunica con bases de datos, servicios ni otros sistemas." }

$ucSearch = Add-Element $pkgFunc "CU01 - Buscar vehiculo" "UseCase" @{ Abstract = $true; Source = "ButtonHandler.actionPerformed (rama SEARCH)";
  Notes = "Caso de uso abstracto. El usuario pulsa 'Search' (Alt+S). El sistema lee la categoria y el tipo seleccionados, obtiene la fabrica concreta con VehicleFactory.getVehicleFactory(tipo), crea el producto correspondiente y muestra 'Name: <nombre>  Features: <caracteristicas>'." }
$ucLux = Add-Element $pkgFunc "CU02 - Buscar vehiculo de lujo" "UseCase" @{ Source = "ButtonHandler.actionPerformed: if (vhCategory.equals(AutoSearchUI.LUXURY))";
  Notes = "Especializacion de CU01 cuando la categoria es 'Luxury': se usa vf.getLuxury() y se consultan getLuxuryName() / getLuxuryFeatures()." }
$ucNon = Add-Element $pkgFunc "CU03 - Buscar vehiculo no lujoso" "UseCase" @{ Source = "ButtonHandler.actionPerformed: if (vhCategory.equals(AutoSearchUI.NON_LUXURY))";
  Notes = "Especializacion de CU01 cuando la categoria es 'Non-Luxury': se usa vf.getNonLuxury() y se consultan getNLName() / getNLFeatures()." }
$ucCrit = Add-Element $pkgFunc "CU04 - Obtener criterios de busqueda" "UseCase" @{ Source = "AutoSearchUI.getSelectedCategory(), AutoSearchUI.getSelectedType()";
  Notes = "Lectura de la categoria (Luxury / Non-Luxury) y del tipo (Car / Suv / Bycicle) seleccionados en los combos. Se ejecuta siempre al buscar." }
$ucShow = Add-Element $pkgFunc "CU05 - Mostrar resultado de busqueda" "UseCase" @{ Source = "AutoSearchUI.setResult(String)";
  Notes = "Escribe el resultado en la etiqueta lblCarNameValue. Se ejecuta siempre al finalizar la busqueda." }
$ucExit = Add-Element $pkgFunc "CU06 - Salir de la aplicacion" "UseCase" @{ Source = "ButtonHandler.actionPerformed (rama EXIT); AutoSearchUI`$1.windowClosing";
  Notes = "Dos disparadores: boton 'Exit' (Alt+X) -> System.exit(1); cerrar la ventana -> System.exit(0). Los codigos de salida difieren en el codigo original." }

$sysBoundary = Add-Element $pkgFunc "Sistema: Abstract Factory - Example (AutoSearchUI)" "Boundary"

[void](Add-Conn $actUser $ucSearch "Association")
[void](Add-Conn $actUser $ucExit   "Association")
[void](Add-Conn $ucLux $ucSearch "Generalization")
[void](Add-Conn $ucNon $ucSearch "Generalization")
[void](Add-Conn $ucSearch $ucCrit "UseCase" @{ Subtype = "Includes"; Stereotype = "include" })
[void](Add-Conn $ucSearch $ucShow "UseCase" @{ Subtype = "Includes"; Stereotype = "include" })

$dUC = New-Diagram $pkgFunc "DCU01 - Diagrama de casos de uso" "Use Case" "Funcionalidades observables de la aplicacion Swing AutoSearchUI."
[void](Add-DiagramObj $dUC $sysBoundary 170 30 700 520 50)
[void](Add-DiagramObj $dUC $actUser      50 225  45 90)
[void](Add-DiagramObj $dUC $ucSearch    240 160 200 60)
[void](Add-DiagramObj $dUC $ucCrit      580  70 240 60)
[void](Add-DiagramObj $dUC $ucShow      580 210 240 60)
[void](Add-DiagramObj $dUC $ucLux       200 320 180 60)
[void](Add-DiagramObj $dUC $ucNon       420 320 200 60)
[void](Add-DiagramObj $dUC $ucExit      240 440 200 60)

# ---------------------------------------------------------------------------
# MODELO DE COMPORTAMIENTO - Diagramas de secuencia
# ---------------------------------------------------------------------------
# Lifeline def: @{ Key; Name; Classifier; Stereotype; Actor (elemento existente) }
# Pasos: @('m', from, to, texto, 'call'|'ret'|'new') | @('fs', 'alt'|'opt'|'loop', guarda, fromKey, toKey) | @('op', guarda) | @('fe')
$fragTypes = @{ 'alt' = 0; 'opt' = 1; 'break' = 2; 'par' = 3; 'loop' = 4 }

function New-SequenceDiagram($pkg, [string]$name, [string]$notes, [object[]]$lifelines, [object[]]$steps, [object[]]$extraNotes = @()) {
  $sub = Add-Package $pkg $name $notes
  $diag = New-Diagram $sub $name "Sequence" $notes

  $X0 = 30; $DX = 165; $LW = 120
  $idx = @{}
  for ($i = 0; $i -lt $lifelines.Count; $i++) { $idx[$lifelines[$i].Key] = $i }

  # ---- Pasada 1: geometria ----
  $y = 100
  $msgs = @(); $frags = @(); $stack = New-Object System.Collections.ArrayList
  $created = @{}
  foreach ($s in $steps) {
    switch ($s[0]) {
      'm' {
        $y += 30
        $msgs += ,@{ From = $s[1]; To = $s[2]; Text = $s[3]; Kind = $s[4]; Y = $y }
        if ($s[4] -eq 'new') { $created[$s[2]] = $y }
      }
      'fs' {
        $top = $y + 14
        $f = @{ Type = $s[1]; Guards = @($s[2]); Starts = @($top); Top = $top; FromKey = $s[3]; ToKey = $s[4]; Depth = $stack.Count }
        [void]$stack.Add($f)
        $y = $top + 12
      }
      'op' {
        $f = $stack[$stack.Count - 1]
        $sep = $y + 14
        $f.Starts += $sep; $f.Guards += $s[1]
        $y = $sep + 12
      }
      'fe' {
        $f = $stack[$stack.Count - 1]; $stack.RemoveAt($stack.Count - 1)
        $f.Bottom = $y + 16
        $frags += ,$f
        $y = $f.Bottom
      }
    }
  }
  $bottom = $y + 50

  # ---- Pasada 2: lineas de vida ----
  $elems = @{}
  for ($i = 0; $i -lt $lifelines.Count; $i++) {
    $ll = $lifelines[$i]
    $x = $X0 + $i * $DX
    if ($ll.Actor) {
      $e = $ll.Actor
      [void](Add-DiagramObj $diag $e ($x + 40) 40 40 ($bottom - 40))
    } else {
      $opt = @{ Notes = $ll.Notes }
      if ($ll.Classifier) { $opt.Classifier = $ll.Classifier }
      if ($ll.Stereotype) { $opt.Stereotype = $ll.Stereotype }
      $e = Add-Element $sub $ll.Name "Sequence" $opt
      $top = 40
      if ($created.ContainsKey($ll.Key)) { $top = $created[$ll.Key] - 25 }
      [void](Add-DiagramObj $diag $e $x $top $LW ($bottom - $top))
    }
    $elems[$ll.Key] = $e
  }

  # ---- Fragmentos combinados ----
  foreach ($f in $frags) {
    $li = $idx[$f.FromKey]; $ri = $idx[$f.ToKey]
    $l = $X0 + $li * $DX - 12 + $f.Depth * 8
    $r = $X0 + $ri * $DX + $LW + 12 - $f.Depth * 8
    $fe = Add-Element $sub "" "InteractionFragment" @{ Subtype = $fragTypes[$f.Type] }
    for ($k = 0; $k -lt $f.Guards.Count; $k++) {
      $end = if ($k -lt $f.Guards.Count - 1) { $f.Starts[$k + 1] } else { $f.Bottom }
      $p = $fe.Partitions.AddNew($f.Guards[$k], "")
      $p.Size = [int]($end - $f.Starts[$k])
    }
    [void]$fe.Update()
    [void](Add-DiagramObj $diag $fe $l $f.Top ($r - $l) ($f.Bottom - $f.Top))
  }

  # ---- Mensajes ----
  $seq = 1
  foreach ($m in $msgs) {
    $src = $elems[$m.From]; $dst = $elems[$m.To]
    $c = $src.Connectors.AddNew($m.Text, "Sequence")
    $c.SupplierID = $dst.ElementID
    $c.DiagramID = $diag.DiagramID
    $c.SequenceNo = $seq++
    [void]$c.Update()
    $isRet = if ($m.Kind -eq 'ret') { '1' } else { '0' }
    $subT  = if ($m.Kind -eq 'new') { "'New'" } else { "NULL" }
    $yy = - $m.Y
    $repo.Execute("UPDATE t_connector SET PtStartY=$yy, PtEndY=$yy, PDATA1='Synchronous', PDATA3='Call', PDATA4='$isRet', SubType=$subT WHERE Connector_ID=$($c.ConnectorID)")
  }

  # ---- Notas ----
  foreach ($n in $extraNotes) {
    $ne = Add-Element $sub "" "Note" @{ Notes = $n.Text }
    $nx = if ($n.ContainsKey('X')) { $n.X } else { $X0 + $lifelines.Count * $DX + 10 }
    [void](Add-DiagramObj $diag $ne $nx $n.Y $n.W $n.H)
  }
  return $diag
}

# ---- SD01 Iniciar la aplicacion ----
$sd1 = New-SequenceDiagram $pkgBeh "DS01 - Iniciar la aplicacion" "Arranque: AutoSearchUI.main(String[]) crea la ventana, sus combos, botones y manejadores de eventos y la hace visible. Se omiten las etiquetas JLabel, el JPanel, el GridBagLayout/GridBagConstraints y SwingUtilities.updateComponentTreeUI por no intervenir en la logica." @(
  @{ Key = 'u';   Actor = $actUser }
  @{ Key = 'cls'; Name = ""; Classifier = $cUI; Stereotype = "static"; Notes = "Contexto estatico: AutoSearchUI.main(String[])." }
  @{ Key = 'frm'; Name = "frame"; Classifier = $cUI }
  @{ Key = 'cc';  Name = "cmbVehicleCategory"; Classifier = $xJComboBox }
  @{ Key = 'ct';  Name = "cmbVehicleType"; Classifier = $xJComboBox }
  @{ Key = 'ob';  Name = "openButton"; Classifier = $xJButton }
  @{ Key = 'eb';  Name = "exitButton"; Classifier = $xJButton }
  @{ Key = 'bh';  Name = "objButtonHandler"; Classifier = $cBH }
  @{ Key = 'bh2'; Name = ""; Classifier = $cBH; Notes = "Manejador anonimo del boton Exit creado con new ButtonHandler() (objAutoSearchUI = null)." }
  @{ Key = 'wa';  Name = ""; Classifier = $cAnon }
) @(
  ,@('m','u','cls','main(args)','call')
  ,@('m','cls','frm','AutoSearchUI()','new')
  ,@('m','frm','cc','JComboBox()','new')
  ,@('m','frm','cc','addItem(AutoSearchUI.LUXURY)','call')
  ,@('m','frm','cc','addItem(AutoSearchUI.NON_LUXURY)','call')
  ,@('m','frm','ct','JComboBox()','new')
  ,@('m','frm','ct','addItem(VehicleFactory.CAR)','call')
  ,@('m','frm','ct','addItem(VehicleFactory.SUV)','call')
  ,@('m','frm','ct','addItem(VehicleFactory.BYCICLE)','call')
  ,@('m','frm','ob','JButton(AutoSearchUI.SEARCH)','new')
  ,@('m','frm','ob','setMnemonic(KeyEvent.VK_S)','call')
  ,@('m','frm','eb','JButton(AutoSearchUI.EXIT)','new')
  ,@('m','frm','eb','setMnemonic(KeyEvent.VK_X)','call')
  ,@('m','frm','bh','ButtonHandler(this)','new')
  ,@('m','frm','ob','addActionListener(objButtonHandler)','call')
  ,@('m','frm','bh2','ButtonHandler()','new')
  ,@('m','frm','eb','addActionListener(new ButtonHandler())','call')
  ,@('m','frm','cls','frame','ret')
  ,@('m','cls','wa','AutoSearchUI$1()','new')
  ,@('m','cls','frm','addWindowListener(windowAdapter)','call')
  ,@('m','cls','frm','setSize(1050, 600)','call')
  ,@('m','cls','frm','setVisible(true)','call')
) @(
  @{ Text = "Omitido por abstraccion: creacion de JLabel, JPanel, GridBagLayout y llamadas setConstraints/add, y SwingUtilities.updateComponentTreeUI(this) dentro de try/catch (setLookAndFeel esta comentado).`r`n`r`nmain() no usa SwingUtilities.invokeLater: la GUI se crea fuera del hilo de eventos (EDT)."; Y = 60; W = 260; H = 170 }
)

# ---- SD02 / SD03 Buscar vehiculo ----
function New-SearchDiagram($name, $notes, [bool]$luxury) {
  if ($luxury) {
    $getOp = 'getLuxury()'; $nameOp = 'getLuxuryName()'; $featOp = 'getLuxuryFeatures()'; $var = 'c'
    $pCar = $cLuxuryCAR; $pSuv = $cLuxurySUV; $pByc = $cLuxuryBYC
    $ctorCar = 'LuxuryCAR("Luxury-Car")'; $ctorSuv = 'LuxurySUV("Luxury-SUV")'; $ctorByc = 'LuxuryBYCICLE("Luxury-Bycicle")'
    $nCar = '"Luxury-Car"'; $fCar = '"Luxury Car Features "'; $nSuv = '"Luxury-SUV"'; $fSuv = '"Luxury SUV Features "'
    $nByc = '"Luxury-Bycicle"'; $fByc = '"Luxury Bycicle Features "'
    $cat = '"Luxury"'; $catGuard = '[vhCategory.equals(AutoSearchUI.LUXURY)]'
  } else {
    $getOp = 'getNonLuxury()'; $nameOp = 'getNLName()'; $featOp = 'getNLFeatures()'; $var = 's'
    $pCar = $cNonLuxuryCAR; $pSuv = $cNonLuxurySUV; $pByc = $cNonLuxuryBYC
    $ctorCar = 'NonLuxuryCAR("NonLuxuryL-Car")'; $ctorSuv = 'NonLuxurySUV("Non-Luxury-SUV")'; $ctorByc = 'NonLuxuryBYCICLE("NonLuxuryL-Bycicle")'
    $nCar = '"NonLuxuryL-Car"'; $fCar = '"Non-Luxury CAR Features "'; $nSuv = '"Non-Luxury-SUV"'; $fSuv = '"Non-Luxury SUV Features "'
    $nByc = '"NonLuxuryL-Bycicle"'; $fByc = '"Non-Luxury BYCICLE Features "'
    $cat = '"Non-Luxury"'; $catGuard = '[vhCategory.equals(AutoSearchUI.NON_LUXURY)]'
  }
  return New-SequenceDiagram $pkgBeh $name $notes @(
    @{ Key = 'u';   Actor = $actUser }
    @{ Key = 'ob';  Name = "openButton"; Classifier = $xJButton }
    @{ Key = 'bh';  Name = "objButtonHandler"; Classifier = $cBH }
    @{ Key = 'frm'; Name = "frame"; Classifier = $cUI }
    @{ Key = 'lbl'; Name = "lblCarNameValue"; Classifier = $xJLabel }
    @{ Key = 'vf';  Name = ""; Classifier = $cVF; Stereotype = "static"; Notes = "Contexto estatico: VehicleFactory.getVehicleFactory(String)." }
    @{ Key = 'fc';  Name = "vf"; Classifier = $cCARVF }
    @{ Key = 'fs';  Name = "vf"; Classifier = $cSUVVF }
    @{ Key = 'fb';  Name = "vf"; Classifier = $cBYCVF }
    @{ Key = 'pc';  Name = $var; Classifier = $pCar }
    @{ Key = 'ps';  Name = $var; Classifier = $pSuv }
    @{ Key = 'pb';  Name = $var; Classifier = $pByc }
  ) @(
    ,@('m','u','ob','pulsar "Search" (Alt+S)','call')
    ,@('m','ob','bh','actionPerformed(e)','call')
    ,@('fs','opt','[e.getActionCommand().equals(AutoSearchUI.SEARCH)]','bh','pb')
      ,@('m','bh','frm','getSelectedCategory()','call')
      ,@('m','frm','bh',"vhCategory = $cat",'ret')
      ,@('m','bh','frm','getSelectedType()','call')
      ,@('m','frm','bh','vhType','ret')
      ,@('m','bh','vf','getVehicleFactory(vhType)','call')
      ,@('fs','alt','[vhType.equals(VehicleFactory.CAR)  o  valor no reconocido (por defecto)]','vf','fb')
        ,@('m','vf','fc','CARVehicleFactory()','new')
      ,@('op','[vhType.equals(VehicleFactory.SUV)]')
        ,@('m','vf','fs','SUVVehicleFactory()','new')
      ,@('op','[vhType.equals(VehicleFactory.BYCICLE)]')
        ,@('m','vf','fb','BYCICLEVehicleFactory()','new')
      ,@('fe')
      ,@('m','vf','bh','vf','ret')
      ,@('fs','opt',$catGuard,'bh','pb')
        ,@('fs','alt','[vf es CARVehicleFactory]  (despacho polimorfico)','bh','pb')
          ,@('m','bh','fc',$getOp,'call')
          ,@('m','fc','pc',$ctorCar,'new')
          ,@('m','fc','bh',$var,'ret')
          ,@('m','bh','pc',$nameOp,'call')
          ,@('m','pc','bh',$nCar,'ret')
          ,@('m','bh','pc',$featOp,'call')
          ,@('m','pc','bh',$fCar,'ret')
        ,@('op','[vf es SUVVehicleFactory]')
          ,@('m','bh','fs',$getOp,'call')
          ,@('m','fs','ps',$ctorSuv,'new')
          ,@('m','fs','bh',$var,'ret')
          ,@('m','bh','ps',$nameOp,'call')
          ,@('m','ps','bh',$nSuv,'ret')
          ,@('m','bh','ps',$featOp,'call')
          ,@('m','ps','bh',$fSuv,'ret')
        ,@('op','[vf es BYCICLEVehicleFactory]')
          ,@('m','bh','fb',$getOp,'call')
          ,@('m','fb','pb',$ctorByc,'new')
          ,@('m','fb','bh',$var,'ret')
          ,@('m','bh','pb',$nameOp,'call')
          ,@('m','pb','bh',$nByc,'ret')
          ,@('m','bh','pb',$featOp,'call')
          ,@('m','pb','bh',$fByc,'ret')
        ,@('fe')
      ,@('fe')
      ,@('m','bh','frm','setResult(searchResult)','call')
      ,@('m','frm','lbl','setText(searchResult)','call')
    ,@('fe')
  ) @(
    @{ Text = "searchResult = `"Name: `" + nombre + `"  Features: `" + caracteristicas`r`n`r`nAntes de la rama SEARCH, actionPerformed evalua e.getActionCommand().equals(EXIT), que es falso en este escenario.`r`n`r`nButtonHandler solo conoce VehicleFactory y $($(if($luxury){'Luxury'}else{'NonLuxury'})): la clase concreta del producto depende de la fabrica devuelta."; Y = 60; W = 260; H = 190 }
  )
}

$sd2 = New-SearchDiagram "DS02 - Buscar vehiculo de lujo" "Escenario de CU02: el usuario elige la categoria 'Luxury' y un tipo (Car / Suv / Bycicle) y pulsa 'Search'." $true
$sd3 = New-SearchDiagram "DS03 - Buscar vehiculo no lujoso" "Escenario de CU03: el usuario elige la categoria 'Non-Luxury' y un tipo (Car / Suv / Bycicle) y pulsa 'Search'." $false

# ---- SD04 Salir de la aplicacion ----
$sd4 = New-SequenceDiagram $pkgBeh "DS04 - Salir de la aplicacion" "Escenario de CU06. Dos formas de terminar: boton 'Exit' (System.exit(1)) o cierre de la ventana (System.exit(0))." @(
  @{ Key = 'u';   Actor = $actUser }
  @{ Key = 'eb';  Name = "exitButton"; Classifier = $xJButton }
  @{ Key = 'bh2'; Name = ""; Classifier = $cBH; Notes = "Manejador creado con new ButtonHandler(): objAutoSearchUI = null." }
  @{ Key = 'frm'; Name = "frame"; Classifier = $cUI }
  @{ Key = 'wa';  Name = ""; Classifier = $cAnon }
  @{ Key = 'sys'; Name = ""; Classifier = $xSystem; Stereotype = "static" }
) @(
  ,@('fs','alt','[el usuario pulsa el boton "Exit"]','u','sys')
    ,@('m','u','eb','pulsar "Exit" (Alt+X)','call')
    ,@('m','eb','bh2','actionPerformed(e)','call')
    ,@('fs','opt','[e.getActionCommand().equals(AutoSearchUI.EXIT)]','bh2','sys')
      ,@('m','bh2','sys','exit(1)','call')
    ,@('fe')
  ,@('op','[el usuario cierra la ventana]')
    ,@('m','u','frm','cerrar ventana (WINDOW_CLOSING)','call')
    ,@('m','frm','wa','windowClosing(e)','call')
    ,@('m','wa','sys','exit(0)','call')
  ,@('fe')
) @(
  @{ Text = "El codigo de salida es distinto segun el disparador: 1 con el boton Exit y 0 al cerrar la ventana.`r`n`r`nEl manejador del boton Exit no tiene referencia a la vista (null); si recibiera el comando 'Search' lanzaria NullPointerException, pero el boton Exit solo emite 'Exit'."; Y = 60; W = 260; H = 170 }
)

# ---------------------------------------------------------------------------
# Cierre
# ---------------------------------------------------------------------------
$repo.RefreshModelView(0)

if ($PreviewDir) {
  if (-not (Test-Path $PreviewDir)) { New-Item -ItemType Directory $PreviewDir | Out-Null }
  $pi = $repo.GetProjectInterface()
  foreach ($d in @($dUC, $dClass, $sd1, $sd2, $sd3, $sd4)) {
    $dd = $repo.GetDiagramByID($d.DiagramID)
    $file = Join-Path $PreviewDir ($dd.Name.Split(' ')[0] + ".png")
    [void]$pi.PutDiagramImageToFile($dd.DiagramGUID, $file, 1)
  }
}

$repo.CloseFile()
$repo.Exit()
[void][Runtime.InteropServices.Marshal]::ReleaseComObject($repo)
Write-Output "Proyecto generado: $OutFile"
