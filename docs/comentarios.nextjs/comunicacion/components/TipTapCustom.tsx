import {
  Box,
  Button,
  Grid,
  IconButton,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem,
  Stack,
  TextField,
  ToggleButton,
  ToggleButtonGroup,
  Tooltip,
  useTheme,
} from '@mui/material'

import Link from '@tiptap/extension-link'
import Table from '@tiptap/extension-table'
import TableCell from '@tiptap/extension-table-cell'
import TableHeader from '@tiptap/extension-table-header'
import TableRow from '@tiptap/extension-table-row'
import Underline from '@tiptap/extension-underline'
import TextAlign from '@tiptap/extension-text-align'
import { Editor, EditorContent, useEditor } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import { MouseEvent, useCallback, useRef, useState } from 'react'
import xss from 'xss'
import { styled } from '@mui/material/styles'
import Divider from '@mui/material/Divider'
import React from 'react'
import { Icono } from '@/components/Icono'

interface MenuBarProps {
  editor: Editor
  mostrarOpcionesFormatoTexto?: boolean
  mostrarOpcionesAlineacion?: boolean
  mostrarOpcionesLista?: boolean
  mostrarOpcionesURL?: boolean
  mostrarOpcionesTabla?: boolean
  mostrarOpcionesHistorial?: boolean
  onBlurMenu?: () => void
  onFocusMenu?: () => void
}

interface TipTapProps {
  editable: boolean
  contenido: string
  placeholder?: string
  onChange: (contenido: string) => void
  mostrarOpcionesFormatoTexto?: boolean
  mostrarOpcionesAlineacion?: boolean
  mostrarOpcionesLista?: boolean
  mostrarOpcionesURL?: boolean
  mostrarOpcionesTabla?: boolean
  mostrarOpcionesHistorial?: boolean
  onBlurTipTap?: () => void
  onFocusTipTap?: () => void
  onBlurMenu?: () => void
  onFocusMenu?: () => void
}

interface TableType {
  filas: number
  columnas: number
}

const StyledToggleButtonGroup = styled(ToggleButtonGroup)(({ theme }) => ({
  '& .MuiToggleButtonGroup-grouped': {
    margin: theme.spacing(0),
    border: `0.1px solid ${theme.palette.grey[100]}`,
    '&.Mui-disabled': {
      border: 0,
    },
    '&:not(:first-of-type)': {
      borderRadius: theme.shape.borderRadius,
    },
    '&:first-of-type': {
      borderRadius: theme.shape.borderRadius,
    },
  },
}))

const MenuBar = ({
  editor,
  mostrarOpcionesFormatoTexto = true,
  mostrarOpcionesAlineacion = true,
  mostrarOpcionesLista = true,
  mostrarOpcionesURL = true,
  mostrarOpcionesTabla = true,
  mostrarOpcionesHistorial = true,
  onBlurMenu,
  onFocusMenu,
}: MenuBarProps) => {
  //Enfoque y desenfoque
  const handleBlur = () => {
    if (onBlurMenu) {
      onBlurMenu()
    }
  }

  const handleFocus = () => {
    if (onFocusMenu) {
      onFocusMenu()
    }
  }
  // Menu tabla

  const [elementosMenuTabla, setElementosMenuTabla] =
    useState<null | HTMLElement>(null)

  const abrirMenuTabla = (event: MouseEvent<HTMLElement>) => {
    setElementosMenuTabla(event.currentTarget)
  }
  const cerrarMenuTabla = () => {
    setElementosMenuTabla(null)
  }

  const tablaCreacion = useRef<TableType>({ filas: 3, columnas: 3 })

  // Menu párrafo

  const [buttonLinkReferencia, setButtonLinkReferencia] =
    useState<null | HTMLElement>(null)
  const [linkPrevio, setLinkPrevio] = useState('')

  const setLink = useCallback(
    (auxLink: string) => {
      const url = auxLink
      // cancelled
      if (url === null) {
        return
      }

      // empty
      if (url === '') {
        editor.chain().focus().extendMarkRange('link').unsetLink().run()
        return
      }

      // update link
      editor
        .chain()
        .focus()
        .extendMarkRange('link')
        .setLink({ href: url })
        .run()
    },
    [editor]
  )

  const abrirPopperLink = (event: MouseEvent<HTMLElement>) => {
    setButtonLinkReferencia(buttonLinkReferencia ? null : event.currentTarget)
  }
  const cerrarPopperLink = () => {
    setButtonLinkReferencia(null)
  }

  const gruposOpciones = [
    /* Formato Texto */
    mostrarOpcionesFormatoTexto && (
      <StyledToggleButtonGroup>
        <Tooltip title="Negrita" placement="bottom-start">
          <ToggleButton
            size="small"
            onClick={() => editor.chain().focus().toggleBold().run()}
            value={'bold'}
            selected={editor.isActive('bold')}
          >
            <Icono color={'inherit'} fontSize="small">
              format_bold
            </Icono>
          </ToggleButton>
        </Tooltip>
        {/* Italic */}
        <Tooltip title="Cursiva" placement="bottom-start">
          <ToggleButton
            size="small"
            onClick={() => editor.chain().focus().toggleItalic().run()}
            value={'italic'}
            selected={editor.isActive('italic')}
          >
            <Icono color={'inherit'} fontSize="small">
              format_italic
            </Icono>
          </ToggleButton>
        </Tooltip>
        {/* Subrayado */}
        <Tooltip title="Subrayado" placement="bottom-start">
          <ToggleButton
            size="small"
            onClick={() => editor.chain().focus().toggleUnderline().run()}
            value={'underline'}
            selected={editor.isActive('underline')}
          >
            <Icono color={'inherit'} fontSize="small">
              format_underlined
            </Icono>
          </ToggleButton>
        </Tooltip>
      </StyledToggleButtonGroup>
    ),
    /* Alinear */

    mostrarOpcionesAlineacion && (
      <StyledToggleButtonGroup>
        <Tooltip title="Izquierda" placement="bottom-start">
          <ToggleButton
            size="small"
            value={'izquierda'}
            onClick={() => editor.chain().focus().setTextAlign('left').run()}
            selected={editor.isActive({ textAlign: 'left' })}
          >
            <Icono color={'inherit'}>format_align_left</Icono>
          </ToggleButton>
        </Tooltip>
        <Tooltip title="Centro" placement="bottom-start">
          <ToggleButton
            size="small"
            value={'centro'}
            onClick={() => editor.chain().focus().setTextAlign('center').run()}
            selected={editor.isActive({ textAlign: 'center' })}
          >
            <Icono color={'inherit'}>format_align_center</Icono>
          </ToggleButton>
        </Tooltip>
        <Tooltip title="Derecha" placement="bottom-start">
          <ToggleButton
            size="small"
            value={'right'}
            onClick={() => editor.chain().focus().setTextAlign('right').run()}
            selected={editor.isActive({ textAlign: 'right' })}
          >
            <Icono color={'inherit'}>format_align_right</Icono>
          </ToggleButton>
        </Tooltip>
        <Tooltip title="Justificado" placement="bottom-start">
          <ToggleButton
            size="small"
            value={'justificado'}
            onClick={() => editor.chain().focus().setTextAlign('justify').run()}
            selected={editor.isActive({ textAlign: 'justify' })}
          >
            <Icono color={'inherit'}>format_align_justify</Icono>
          </ToggleButton>
        </Tooltip>
      </StyledToggleButtonGroup>
    ),
    /* Opciones lista */
    mostrarOpcionesLista && (
      <StyledToggleButtonGroup>
        <Tooltip title="Lista ordenada" placement="bottom-start">
          <ToggleButton
            size="small"
            onClick={() => editor.chain().focus().toggleOrderedList().run()}
            value={'orderedList'}
            selected={editor.isActive('orderedList')}
          >
            <Icono color={'inherit'} fontSize="small">
              format_list_numbered
            </Icono>
          </ToggleButton>
        </Tooltip>
        {/* Lista de puntos */}
        <Tooltip title="Lista de puntos" placement="bottom-start">
          <ToggleButton
            size="small"
            onClick={() => editor.chain().focus().toggleBulletList().run()}
            value={'bulletList'}
            selected={editor.isActive('bulletList')}
          >
            <Icono color={'inherit'} fontSize="small">
              format_list_bulleted
            </Icono>
          </ToggleButton>
        </Tooltip>
      </StyledToggleButtonGroup>
    ),
    /* Opciones URL */
    mostrarOpcionesURL && (
      <StyledToggleButtonGroup>
        <Tooltip title="Crear enlace" placement="bottom-start">
          <ToggleButton
            size="small"
            value={'link'}
            selected={editor.isActive('link')}
            onClick={abrirPopperLink}
          >
            <Icono color={'inherit'} fontSize="small">
              link
            </Icono>
          </ToggleButton>
        </Tooltip>
      </StyledToggleButtonGroup>
    ),
    /* Tablas  */
    mostrarOpcionesTabla && (
      <StyledToggleButtonGroup>
        <Tooltip title="Opciones Tabla" placement="bottom-start">
          <ToggleButton size="small" value={'tablas'} onClick={abrirMenuTabla}>
            <Icono color={'inherit'} fontSize="small">
              table_chart
            </Icono>
            <Icono color={'inherit'} fontSize="small">
              arrow_drop_down
            </Icono>
          </ToggleButton>
        </Tooltip>
      </StyledToggleButtonGroup>
    ),
    /* Historial */
    mostrarOpcionesHistorial && (
      <StyledToggleButtonGroup>
        <Tooltip title="Deshacer" placement="bottom-start">
          <ToggleButton
            size="small"
            value={'undo'}
            onClick={() => editor.chain().focus().undo().run()}
          >
            <Icono color={'inherit'} fontSize="small">
              undo
            </Icono>
          </ToggleButton>
        </Tooltip>
        <Tooltip title="Rehacer" placement="bottom-start">
          <ToggleButton
            size="small"
            value={'undo'}
            onClick={() => editor.chain().focus().redo().run()}
          >
            <Icono color={'inherit'} fontSize="small">
              redo
            </Icono>
          </ToggleButton>
        </Tooltip>
      </StyledToggleButtonGroup>
    ),
  ]

  return (
    <>
      <Box onBlur={handleBlur} onFocus={handleFocus}>
        {/* Menu de tabla */}
        <Menu
          sx={{ mt: 0.5 }}
          id="menu-tabla"
          anchorEl={elementosMenuTabla}
          open={Boolean(elementosMenuTabla)}
          onClose={cerrarMenuTabla}
          MenuListProps={{
            'aria-labelledby': 'basic-button',
          }}
        >
          {/* Insertar tabla */}
          <Box>
            {tablaCreacion && (
              <Stack
                sx={{ ml: 2, mr: 2 }}
                direction={'row'}
                alignItems={'center'}
                // justifyContent={'flex-start'}
              >
                <ListItemText>Tabla Nueva</ListItemText>
                <TextField
                  sx={{ width: 60, transform: 'scale(0.75)' }}
                  defaultValue={tablaCreacion.current.columnas}
                  label="Columna"
                  type="number"
                  inputProps={{ min: 1 }}
                  onChange={(e) => {
                    tablaCreacion.current.columnas = parseInt(e.target.value)
                  }}
                />
                <TextField
                  type="number"
                  label="Fila"
                  inputProps={{ min: 1 }}
                  sx={{ width: 60, transform: 'scale(0.75)' }}
                  defaultValue={tablaCreacion.current.filas}
                  onChange={(e) => {
                    tablaCreacion.current.filas = parseInt(e.target.value)
                  }}
                />
                <Button
                  variant="outlined"
                  size="small"
                  sx={{ mt: 0.6 }}
                  onClick={() => {
                    editor
                      .chain()
                      .focus()
                      .insertTable({
                        rows: tablaCreacion.current.filas,
                        cols: tablaCreacion.current.columnas,
                        withHeaderRow: true,
                      })
                      .run()
                  }}
                >
                  Adicionar
                  <Icono sx={{ ml: 1 }} color="inherit" fontSize="small">
                    add_circle
                  </Icono>
                </Button>
              </Stack>
            )}
          </Box>
          {/* Adicionar columna antes */}
          <MenuItem
            onClick={() => editor.chain().focus().addColumnBefore().run()}
            disabled={!editor.can().addColumnBefore()}
          >
            <ListItemIcon>
              <Icono fontSize="small">add</Icono>
            </ListItemIcon>
            <ListItemText>Adicionar columna antes</ListItemText>
          </MenuItem>
          {/* Adicionar fila después */}
          <MenuItem
            onClick={() => editor.chain().focus().addColumnAfter().run()}
            disabled={!editor.can().addColumnAfter()}
          >
            <ListItemIcon>
              <Icono fontSize="small">add</Icono>
            </ListItemIcon>
            <ListItemText>Adicionar columna después</ListItemText>
          </MenuItem>
          {/* Eliminar columna */}
          <MenuItem
            onClick={() => editor.chain().focus().deleteColumn().run()}
            disabled={!editor.can().deleteColumn()}
          >
            <ListItemIcon>
              <Icono fontSize="small">disabled_by_default</Icono>
            </ListItemIcon>
            <ListItemText>Eliminar columna</ListItemText>
          </MenuItem>
          {/* Adicionar fila antes */}
          <MenuItem
            onClick={() => editor.chain().focus().addRowBefore().run()}
            disabled={!editor.can().addRowBefore()}
          >
            <ListItemIcon>
              <Icono fontSize="small">add</Icono>
            </ListItemIcon>
            <ListItemText>Adicionar fila antes</ListItemText>
          </MenuItem>
          {/* Adicionar fila después */}
          <MenuItem
            onClick={() => editor.chain().focus().addRowAfter().run()}
            disabled={!editor.can().addRowAfter()}
          >
            <ListItemIcon>
              <Icono fontSize="small">add</Icono>
            </ListItemIcon>
            <ListItemText>Adicionar fila después</ListItemText>
          </MenuItem>
          {/* Eliminar fila */}
          <MenuItem
            onClick={() => editor.chain().focus().deleteRow().run()}
            disabled={!editor.can().deleteRow()}
          >
            <ListItemIcon>
              <Icono fontSize="small">disabled_by_default</Icono>
            </ListItemIcon>
            <ListItemText>Eliminar fila</ListItemText>
          </MenuItem>
          {/* Eliminar tabla */}
          <MenuItem
            onClick={() => editor.chain().focus().deleteTable().run()}
            disabled={!editor.can().deleteTable()}
          >
            <ListItemIcon>
              <Icono fontSize="small">delete</Icono>
            </ListItemIcon>
            <ListItemText>Eliminar tabla</ListItemText>
          </MenuItem>
          {/* Unir celdas */}
          <MenuItem
            onClick={() => editor.chain().focus().mergeCells().run()}
            disabled={!editor.can().mergeCells()}
          >
            <ListItemIcon>
              <Icono fontSize="small">commit</Icono>
            </ListItemIcon>
            <ListItemText>Unir celdas</ListItemText>
          </MenuItem>
          {/* Separar celdas */}
          <MenuItem
            onClick={() => editor.chain().focus().splitCell().run()}
            disabled={!editor.can().splitCell()}
          >
            <ListItemIcon>
              <Icono fontSize="small">horizontal_split</Icono>
            </ListItemIcon>
            <ListItemText>Separar celdas</ListItemText>
          </MenuItem>
        </Menu>
        {/* Menu Link */}
        <Menu
          sx={{ mt: 0.5 }}
          id={'id-link'}
          open={Boolean(buttonLinkReferencia)}
          anchorEl={buttonLinkReferencia}
          onClose={cerrarPopperLink}
        >
          <Stack sx={{ p: 1 }}>
            <TextField
              defaultValue={editor.getAttributes('link').href}
              onChange={(e) => {
                setLinkPrevio(e.currentTarget.value)
              }}
              placeholder="https://mipagina.io"
              InputProps={{
                startAdornment: (
                  <Icono sx={{ px: 1 }} color="secondary">
                    public
                  </Icono>
                ),
              }}
            />
            <Stack
              direction={'row'}
              spacing={1}
              alignItems={'flex-end'}
              justifyContent={'flex-end'}
            >
              <IconButton
                onClick={() => {
                  setLink('')
                  cerrarPopperLink()
                }}
                size="small"
              >
                <Icono> link_off</Icono>
              </IconButton>
              <Button
                onClick={() => {
                  setLink(linkPrevio)
                  cerrarPopperLink()
                }}
                size="small"
                variant="outlined"
              >
                Guardar
              </Button>
            </Stack>
          </Stack>
        </Menu>

        <Grid
          container
          direction="row"
          justifyContent="left"
          alignItems="center"
        >
          {gruposOpciones
            .filter((grupo) => grupo)
            .map((grupo, index) => (
              <React.Fragment key={index}>
                {grupo}
                {index !=
                  gruposOpciones.filter((grupo) => grupo).length - 1 && (
                  <Divider
                    flexItem
                    orientation="vertical"
                    sx={{ mx: 0.5, my: 1 }}
                  />
                )}
              </React.Fragment>
            ))}
        </Grid>
      </Box>
    </>
  )
}

const TipTapCustom = ({
  contenido,
  onChange,
  editable = true,
  mostrarOpcionesFormatoTexto,
  mostrarOpcionesAlineacion,
  mostrarOpcionesLista,
  mostrarOpcionesURL,
  mostrarOpcionesTabla,
  mostrarOpcionesHistorial,
  onBlurTipTap,
  onFocusTipTap,
  onBlurMenu,
  onFocusMenu,
}: TipTapProps) => {
  const { palette } = useTheme()

  //Seccion de enfoque y desenfoque
  const handleBlurTiptap = () => {
    if (onBlurTipTap) {
      onBlurTipTap()
    }
  }

  const handleFocusTipTap = () => {
    if (onFocusTipTap) {
      onFocusTipTap()
    }
  }

  const handleBlurMenu = () => {
    if (onBlurMenu) {
      onBlurMenu()
    }
  }

  const handleFocusMenu = () => {
    if (onFocusMenu) {
      onFocusMenu()
    }
  }

  const editor = useEditor({
    editable: editable,

    onUpdate: () => {
      onChange(editor?.getHTML() ?? '')
    },
    onCreate: () => {
      if (editable) {
        onChange(editor?.getHTML() ?? '')
      }
    },

    extensions: [
      TextAlign.configure({
        types: ['heading', 'paragraph'],
      }),
      Underline.configure({
        HTMLAttributes: {
          class: 'underline-class',
        },
      }),
      StarterKit.configure({
        bulletList: {
          // keepMarks: true,
          keepAttributes: false,
        },
        orderedList: {
          // keepMarks: true,
          keepAttributes: false,
        },
      }),
      Table.configure({
        resizable: true,
      }),
      TableRow,
      TableHeader,
      // CustomTableCell,

      TableCell,
      Link.configure({
        openOnClick: !editable,
        linkOnPaste: false,
      }),
    ],
    content: contenido,
  })

  return (
    <Box>
      {editable && (
        <Stack sx={{ pb: 1 }} direction={'row'} justifyContent={'flex-start'}>
          {editor && (
            <MenuBar
              onBlurMenu={handleBlurMenu}
              onFocusMenu={handleFocusMenu}
              mostrarOpcionesFormatoTexto={mostrarOpcionesFormatoTexto}
              mostrarOpcionesAlineacion={mostrarOpcionesAlineacion}
              mostrarOpcionesLista={mostrarOpcionesLista}
              mostrarOpcionesHistorial={mostrarOpcionesHistorial}
              mostrarOpcionesURL={mostrarOpcionesURL}
              mostrarOpcionesTabla={mostrarOpcionesTabla}
              editor={editor}
            />
          )}
        </Stack>
      )}
      {editable ? (
        <EditorContent
          onBlur={handleBlurTiptap}
          onFocus={handleFocusTipTap}
          editor={editor}
        />
      ) : (
        <div
          dangerouslySetInnerHTML={{
            __html: xss(contenido ?? ''),
          }}
        ></div>
      )}
      {editable && (
        <style jsx global>{`
          .ProseMirror {
            padding-left: 20px;
            padding-right: 20px;
            border: 1px solid ${palette.primary.main};
            border-radius: 5px;
          }

          .ProseMirror:focus-visible {
            outline: 0 !important;
            border: 2px solid;

            border-color: ${palette.primary.main} !important;
          }

          .ProseMirror pre {
            background-color: #e3dede;
            padding: 10px;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
          }

          table {
            border-collapse: collapse;
            table-layout: fixed;
            width: 100%;
            margin: 0;
          }

          td,
          th {
            min-width: 1em;
            border: 1px solid;
            padding: 3px 5px;
            vertical-align: top;
            box-sizing: border-box;
            position: relative;
          }

          th {
            text-align: left;
          }

          .selectedCell:after {
            z-index: 2;
            position: absolute;
            content: '';
            left: 0;
            right: 0;
            top: 0;
            bottom: 0;
            background: rgba(210, 210, 210, 0.4);
            pointer-events: none;
          }

          .column-resize-handle {
            position: absolute;
            right: -2px;
            top: 0;
            bottom: -2px;
            width: 2px;
            background-color: ${palette.primary.main};
            pointer-events: none;
          }

          .tableWrapper {
            padding: 1rem 0;
            overflow-x: auto;
          }

          .resize-cursor {
            cursor: col-resize;
          }
          .paragraph {
            /* Estilos comunes para párrafos aquí */
            margin-bottom: 1em;
          }

          .code-block {
            /* Estilos específicos para bloques de código */
            background-color: #f4f4f4; /* Color de fondo gris claro */
            padding: 10px;
            border-radius: 5px;
            font-family: 'Courier New', monospace; /* Fuente de monoespaciado para el código */
          }
        `}</style>
      )}
    </Box>
  )
}

export default TipTapCustom
