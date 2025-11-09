import { FC, ReactNode, useEffect, useRef, useState } from 'react'
import {
  Box,
  Chip,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem,
  Paper,
  Stack,
  Typography,
  alpha,
  useTheme,
} from '@mui/material'
import xss from 'xss'
import TipTapWithAvatar from './TipTapWithAvatar'
import { Icono } from '@/components/Icono'
import relativeTime from 'dayjs/plugin/relativeTime'
import 'dayjs/locale/es'
import dayjs from 'dayjs'
import AvatarCustom from '../../../../../components/avatares/AvatarCustom'
import {
  ComentarioArchivoType,
  ComentarioSubmitPayload,
} from '../types/comentario.type'
import { formatFileSize } from '@/utils'
import { Constantes } from '@/config/Constantes'
import { leerCookie } from '@/utils/cookies'
import { imprimir } from '@/utils/imprimir'
import { RolEnum } from '@/app/admin/(administracion)/nutricionistas/types/usuariosCRUDTypes'
dayjs.extend(relativeTime)
dayjs.locale('es')

const sanitizeBaseUrl = (url: string) => url.replace(/\/$/, '')

const isAbsoluteUrl = (url: string) => /^https?:\/\//i.test(url)

const resolveAttachmentDownloadUrl = (
  archivo: ComentarioArchivoType
): string => {
  const providedUrl = archivo?.urlDescarga ?? ''
  if (providedUrl) {
    if (isAbsoluteUrl(providedUrl)) {
      return providedUrl
    }

    const baseUrl = Constantes.baseUrl
      ? sanitizeBaseUrl(Constantes.baseUrl)
      : ''
    if (!baseUrl) {
      return providedUrl
    }

    return `${baseUrl}${providedUrl.startsWith('/') ? '' : '/'}${providedUrl}`
  }

  const baseUrl = Constantes.baseUrl ? sanitizeBaseUrl(Constantes.baseUrl) : ''
  if (!baseUrl) {
    return ''
  }

  if (archivo?.historiaClinicaId && archivo?.comentarioId) {
    return `${baseUrl}/historia-clinica/${archivo.historiaClinicaId}/comentarios/${archivo.comentarioId}/archivos/${archivo.id}`
  }

  if (archivo?.comentarioId) {
    return `${baseUrl}/comentarios/${archivo.comentarioId}/archivos/${archivo.id}`
  }

  return ''
}

const isTemporaryAttachment = (archivo: ComentarioArchivoType) =>
  archivo?.id?.startsWith('temp-file-')

const canHandleAttachment = (archivo: ComentarioArchivoType) => {
  if (!archivo?.id || isTemporaryAttachment(archivo)) {
    return false
  }

  const url = resolveAttachmentDownloadUrl(archivo)
  return Boolean(url)
}
export interface MenuItemAction {
  key: string
  label: string
  icon: ReactNode
  onClick: () => void
}

export interface CardCommentProps {
  owner: {
    avatarName?: string
    fullName: string
    roleLabel?: string
    roleKey?: string
  }
  userReply: {
    avatarName?: string
    fullName: string
  }
  text: string
  date?: string
  replies?: CardCommentProps[]
  attachments?: ComentarioArchivoType[]
  isOwnMessage?: boolean
  isEdited?: boolean
  onReply?: (payload: ComentarioSubmitPayload) => Promise<void> | void
  onEdit?: (payload: ComentarioSubmitPayload) => Promise<void> | void
  menuItemActions?: Array<MenuItemAction>
  maxFiles?: number
  maxFileSizeMB?: number
  allowedMimeTypes?: string[]
  onValidationError?: (mensaje: string) => void
}

const CardComment: FC<CardCommentProps> = ({
  owner,
  userReply,
  text,
  date,
  replies = [],
  attachments = [],
  isOwnMessage = false,
  isEdited = false,
  onReply,
  onEdit,
  menuItemActions = [],
  maxFiles,
  maxFileSizeMB,
  allowedMimeTypes,
  onValidationError,
}) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
  const open = Boolean(anchorEl)
  const theme = useTheme()
  const [isPreviewOpen, setIsPreviewOpen] = useState(false)
  const [attachmentLoadingId, setAttachmentLoadingId] = useState<string | null>(
    null
  )
  const attachmentCacheRef = useRef(
    new Map<string, { objectUrl: string; mimeType?: string }>()
  )
  const [previewAttachment, setPreviewAttachment] = useState<{
    archivo: ComentarioArchivoType
    objectUrl: string
  } | null>(null)

  const handleOpenMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget)
  }

  const handleCloseMenu = () => {
    setAnchorEl(null)
  }

  //Linea vertical seccion de respuestas
  const componentARef = useRef<HTMLDivElement>(null)
  const componentBRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const setComponentAHeightRelativeToB = () => {
      if (componentARef.current && componentBRef.current) {
        const componentBHeight = componentBRef.current.clientHeight
        componentARef.current.style.height = `calc(100% - ${componentBHeight}px + 10px)`
      }
    }
    setComponentAHeightRelativeToB()
    window.addEventListener('resize', setComponentAHeightRelativeToB)
    return () => {
      window.removeEventListener('resize', setComponentAHeightRelativeToB)
    }
  }, [onReply])
  //

  useEffect(() => {
    const cache = attachmentCacheRef.current
    return () => {
      cache.forEach(({ objectUrl }) => {
        URL.revokeObjectURL(objectUrl)
      })
      cache.clear()
    }
  }, [])

  const [openReply, setOpenReply] = useState<boolean>(false)
  const [openEdit, setOpenEdit] = useState<boolean>(false)

  const handleOpenEdit = () => {
    setOpenEdit(true)
  }

  const handleOpenReply = () => {
    setOpenReply((prevOpen) => !prevOpen)
  }

  const palettePerson = {
    own:
      theme.palette.mode === 'light'
        ? theme.palette.primary.main // azul corporativo
        : '#4D8DFF', // azul más brillante en dark

    patient:
      theme.palette.mode === 'light'
        ? '#455A64' // gris azulado (neutral, serio)
        : '#90A4AE', // gris claro para contraste en dark

    nutritionist:
      theme.palette.mode === 'light'
        ? '#795548' // marrón sobrio (profesional, cálido sin ser suave)
        : '#BCAAA4', // marrón claro equilibrado para dark mode

    admin:
      theme.palette.mode === 'light'
        ? '#B71C1C' // rojo oscuro (autoridad, decisión)
        : '#EF5350', // rojo más luminoso para dark

    fallback:
      theme.palette.mode === 'light'
        ? theme.palette.text.primary
        : theme.palette.text.secondary,
  }

  const normalizedRole = owner.roleKey?.toUpperCase() ?? undefined
  const roleAccentColor =
    normalizedRole === RolEnum.ADMINISTRADOR
      ? palettePerson.admin
      : normalizedRole === RolEnum.NUTRICIONISTA
        ? palettePerson.nutritionist
        : normalizedRole === RolEnum.PACIENTE
          ? palettePerson.patient
          : undefined
  const resolvedAccentColor =
    roleAccentColor ??
    (isOwnMessage ? palettePerson.own : palettePerson.fallback)
  const isAdminRole = normalizedRole === RolEnum.ADMINISTRADOR
  const bubbleBackground = isAdminRole
    ? alpha(resolvedAccentColor, theme.palette.mode === 'light' ? 0.14 : 0.28)
    : isOwnMessage
      ? alpha(resolvedAccentColor, 0.05)
      : 'transparent'
  const borderColor = alpha(resolvedAccentColor, isAdminRole ? 0.85 : 0.65)
  const borderWidth = isOwnMessage ? '2px' : '1.5px'
  const attachmentBackground = isAdminRole
    ? alpha(resolvedAccentColor, theme.palette.mode === 'light' ? 0.12 : 0.24)
    : alpha(resolvedAccentColor, 0.06)
  const attachmentHoverBackground = alpha(
    resolvedAccentColor,
    isAdminRole ? 0.22 : 0.12
  )
  const menuTriggerColor = alpha(resolvedAccentColor, 0.8)
  const attachmentBorderColor = alpha(
    resolvedAccentColor,
    isAdminRole ? 0.7 : 0.55
  )
  const roleChipVariant = isAdminRole ? 'filled' : 'outlined'
  const roleChipStyles = isAdminRole
    ? {
        bgcolor: alpha(
          resolvedAccentColor,
          theme.palette.mode === 'light' ? 0.18 : 0.35
        ),
        color: theme.palette.getContrastText(resolvedAccentColor),
        borderColor: alpha(resolvedAccentColor, 0.7),
        borderWidth: '1px',
      }
    : {
        bgcolor: alpha(
          resolvedAccentColor,
          theme.palette.mode === 'light' ? 0.18 : 0.35
        ),
        color: resolvedAccentColor,
        borderColor: resolvedAccentColor,
        borderWidth: '1px',
      }

  const getAttachmentIcon = (tipo: string) => {
    if (!tipo) {
      return 'attach_file'
    }

    if (tipo.startsWith('image/')) {
      return 'image'
    }

    if (tipo.startsWith('video/')) {
      return 'videocam'
    }

    if (tipo.startsWith('audio/')) {
      return 'audiotrack'
    }

    if (tipo === 'application/pdf') {
      return 'picture_as_pdf'
    }

    return 'attach_file'
  }

  const tipoSoportaModal = (tipo?: string | null) => {
    if (!tipo) return false
    if (tipo.startsWith('image/')) return true
    if (tipo.startsWith('video/')) return true
    if (tipo.startsWith('audio/')) return true
    return tipo === 'application/pdf'
  }

  const ensureAttachmentResource = async (
    archivo: ComentarioArchivoType
  ): Promise<{ objectUrl: string; mimeType?: string } | null> => {
    if (typeof window === 'undefined') {
      return null
    }

    const cached = attachmentCacheRef.current.get(archivo.id)
    if (cached) {
      return cached
    }

    const downloadUrl = resolveAttachmentDownloadUrl(archivo)
    if (!downloadUrl) {
      return null
    }

    try {
      const token = leerCookie('token')
      const headers: Record<string, string> = {
        accept: 'application/octet-stream',
      }

      if (token) {
        headers.Authorization = `Bearer ${token}`
      }

      const response = await fetch(downloadUrl, {
        headers,
        credentials: 'include',
      })

      if (!response.ok) {
        throw new Error(`Error HTTP ${response.status}`)
      }

      const blob = await response.blob()
      const objectUrl = URL.createObjectURL(blob)
      const mimeType = response.headers.get('content-type') ?? undefined
      const recurso = { objectUrl, mimeType }
      attachmentCacheRef.current.set(archivo.id, recurso)
      return recurso
    } catch (error) {
      attachmentCacheRef.current.delete(archivo.id)
      imprimir('Error al obtener el adjunto del comentario', error)
      throw error
    }
  }

  const triggerDownload = (
    archivo: ComentarioArchivoType,
    objectUrl: string
  ) => {
    if (typeof window === 'undefined') {
      return
    }

    const link = document.createElement('a')
    link.href = objectUrl
    link.download = archivo.nombre ?? 'archivo'
    link.rel = 'noopener noreferrer'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  const handleAttachmentInteraction = async (
    archivo: ComentarioArchivoType
  ) => {
    if (!canHandleAttachment(archivo)) {
      onValidationError?.(
        'Este archivo adjunto todavía no está disponible para su descarga.'
      )
      return
    }

    setAttachmentLoadingId(archivo.id)

    try {
      const recurso = await ensureAttachmentResource(archivo)
      if (!recurso) {
        onValidationError?.(
          'No se pudo obtener el archivo adjunto. Inténtalo nuevamente.'
        )
        return
      }

      const tipoResuelto = (archivo.tipo || recurso.mimeType || '').split(
        ';'
      )[0]
      const archivoResuelto = archivo.tipo
        ? archivo
        : { ...archivo, tipo: tipoResuelto }

      if (tipoSoportaModal(tipoResuelto)) {
        setPreviewAttachment({
          archivo: archivoResuelto,
          objectUrl: recurso.objectUrl,
        })
        setIsPreviewOpen(true)
      } else {
        triggerDownload(archivoResuelto, recurso.objectUrl)
      }
    } catch (error) {
      onValidationError?.(
        'No se pudo obtener el archivo adjunto. Inténtalo nuevamente.'
      )
    } finally {
      setAttachmentLoadingId(null)
    }
  }

  const handleDownloadAttachment = async (
    archivo: ComentarioArchivoType,
    objectUrl?: string
  ) => {
    if (!canHandleAttachment(archivo)) {
      onValidationError?.(
        'Este archivo adjunto todavía no está disponible para su descarga.'
      )
      return
    }

    setAttachmentLoadingId(archivo.id)

    try {
      if (objectUrl) {
        triggerDownload(archivo, objectUrl)
        return
      }

      const recurso = await ensureAttachmentResource(archivo)
      if (!recurso) {
        onValidationError?.(
          'No se pudo obtener el archivo adjunto. Inténtalo nuevamente.'
        )
        return
      }

      triggerDownload(archivo, recurso.objectUrl)
    } catch (error) {
      imprimir('Error al descargar el adjunto del comentario', error)
      onValidationError?.(
        'No se pudo descargar el archivo adjunto. Inténtalo nuevamente.'
      )
    } finally {
      setAttachmentLoadingId(null)
    }
  }

  const handleClosePreview = () => {
    setIsPreviewOpen(false)
    setPreviewAttachment(null)
  }

  const renderPreviewContent = (
    attachment: { archivo: ComentarioArchivoType; objectUrl: string } | null
  ) => {
    if (!attachment) {
      return null
    }

    const { archivo, objectUrl } = attachment

    if (!objectUrl) {
      return (
        <Typography variant="body2" color="text.secondary">
          No es posible visualizar este archivo en este momento.
        </Typography>
      )
    }

    const { tipo } = archivo

    if (tipo?.startsWith('image/')) {
      return (
        <Box
          component="img"
          src={objectUrl}
          alt={archivo.nombre}
          sx={{
            maxWidth: '100%',
            height: 'auto',
            borderRadius: 2,
          }}
        />
      )
    }

    if (tipo?.startsWith('video/')) {
      return (
        <Box
          component="video"
          controls
          src={objectUrl}
          sx={{ width: '100%', borderRadius: 2 }}
        />
      )
    }

    if (tipo?.startsWith('audio/')) {
      return (
        <Box
          component="audio"
          controls
          src={objectUrl}
          sx={{ width: '100%' }}
        />
      )
    }

    if (tipo === 'application/pdf') {
      return (
        <Box
          component="iframe"
          src={objectUrl}
          title={archivo.nombre}
          sx={{
            border: 'none',
            width: '100%',
            minHeight: { xs: 360, md: 480 },
          }}
        />
      )
    }

    return null
  }

  return (
    <>
      {/* Lista de acciones */}
      <Paper sx={{ width: 320, maxWidth: '100%' }}>
        <Menu
          anchorEl={anchorEl}
          id="account-menu"
          open={open}
          onClose={handleCloseMenu}
          onClick={handleCloseMenu}
          transformOrigin={{ horizontal: 'right', vertical: 'top' }}
          anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
        >
          {menuItemActions?.map(({ key, label, icon, onClick }) => (
            <MenuItem key={`menu-item-${key}`} onClick={() => onClick()}>
              <ListItemIcon>{icon}</ListItemIcon>
              <ListItemText>
                <Typography variant={'body2'}>{label}</Typography>
              </ListItemText>
            </MenuItem>
          ))}
        </Menu>
      </Paper>
      {/* Card de edicion */}
      {openEdit ? (
        <TipTapWithAvatar
          fullName={owner.fullName}
          avatarName={owner.avatarName}
          contenido={text}
          enableAttachments={false}
          onValidationError={onValidationError}
          onAccept={{
            label: 'Guardar',
            execute: async ({ contenido }) => {
              if (onEdit) {
                await onEdit({ contenido, archivos: [] })
                setOpenEdit(false)
              }
            },
          }}
          onCancel={{
            label: 'Cancelar',
            execute: () => {
              setOpenEdit(false)
            },
          }}
        />
      ) : (
        <Box>
          {/* Card de comentario */}
          <Box display={'flex'} gap={1.5} position={'relative'}>
            {replies.length !== 0 && (
              <Box
                borderLeft={'2px solid'}
                sx={{ borderLeftColor: 'divider' }}
                position={'absolute'}
                height={'100%'}
                top={20}
                left={15}
              />
            )}
            <AvatarCustom
              avatarName={owner.avatarName}
              fullName={owner.fullName}
              size="medium"
            />
            <Box flexGrow={1}>
              <Paper
                elevation={0}
                sx={{
                  position: 'relative',
                  borderRadius: 3,
                  bgcolor: bubbleBackground,
                  borderColor,
                  borderStyle: 'solid',
                  borderWidth,
                  px: { xs: 2, md: 2.5 },
                  py: { xs: 1.5, md: 1.75 },
                  '&:hover .comment-menu-trigger': {
                    opacity: 1,
                  },
                  minWidth: 0,
                }}
              >
                <Box display="flex" alignItems="flex-start" gap={1.5}>
                  <Box flexGrow={1} minWidth={0}>
                    <Stack
                      direction="row"
                      spacing={1}
                      alignItems="baseline"
                      flexWrap="wrap"
                      sx={{ mb: 0.5 }}
                    >
                      <Typography
                        variant="subtitle2"
                        fontWeight={600}
                        color={alpha(resolvedAccentColor, 0.9)}
                      >
                        {`${owner.fullName}${isOwnMessage ? ' (Tú)' : ''}`}
                      </Typography>
                      {owner.roleLabel && (
                        <Chip
                          size="small"
                          variant={roleChipVariant}
                          label={owner.roleLabel}
                          sx={{
                            height: 22,
                            fontWeight: 600,
                            textTransform: 'none',
                            px: 0.5,
                            ...roleChipStyles,
                          }}
                        />
                      )}
                    </Stack>
                    <Box
                      component="div"
                      sx={{
                        typography: 'body2',
                        lineHeight: 1.6,
                        wordBreak: 'break-word',
                        '& p': { margin: 0 },
                        '& a': {
                          color: resolvedAccentColor,
                          textDecoration: 'underline',
                        },
                        '& ul, & ol': {
                          paddingInlineStart: 3,
                          marginBlock: 0.5,
                        },
                      }}
                    >
                      <div
                        dangerouslySetInnerHTML={{
                          __html: xss(text ?? ''),
                        }}
                      />
                    </Box>
                    {isEdited && (
                      <Typography
                        variant="caption"
                        color={alpha(resolvedAccentColor, 0.7)}
                        mt={0.75}
                        display="block"
                      >
                        Editado
                      </Typography>
                    )}
                    {attachments.length > 0 && (
                      <Stack spacing={1} mt={1.5}>
                        {attachments.map((archivo) => {
                          const puedeGestionarse = canHandleAttachment(archivo)
                          const estaCargando =
                            attachmentLoadingId === archivo.id

                          return (
                            <Button
                              key={archivo.id}
                              variant="outlined"
                              size="small"
                              startIcon={
                                estaCargando ? (
                                  <CircularProgress size={16} />
                                ) : (
                                  <Icono fontSize="small">
                                    {getAttachmentIcon(archivo.tipo)}
                                  </Icono>
                                )
                              }
                              onClick={() => {
                                void handleAttachmentInteraction(archivo)
                              }}
                              disabled={!puedeGestionarse || estaCargando}
                              sx={{
                                justifyContent: 'space-between',
                                borderRadius: 2,
                                px: 1.5,
                                borderColor: attachmentBorderColor,
                                bgcolor: attachmentBackground,
                                color: isOwnMessage
                                  ? theme.palette.primary.dark
                                  : theme.palette.text.primary,
                                '&:hover': {
                                  borderColor: resolvedAccentColor,
                                  bgcolor: attachmentHoverBackground,
                                },
                              }}
                            >
                              <Box
                                display="flex"
                                flexDirection="column"
                                alignItems="flex-start"
                                sx={{ minWidth: 0 }}
                              >
                                <Typography
                                  variant="caption"
                                  color="text.primary"
                                  sx={{
                                    fontWeight: 600,
                                    maxWidth: '100%',
                                    textOverflow: 'ellipsis',
                                    overflow: 'hidden',
                                  }}
                                >
                                  {archivo.nombre}
                                </Typography>
                                {archivo.pesoBytes !== undefined && (
                                  <Typography
                                    variant="caption"
                                    color="text.secondary"
                                  >
                                    {formatFileSize(archivo.pesoBytes)}
                                  </Typography>
                                )}
                              </Box>
                            </Button>
                          )
                        })}
                      </Stack>
                    )}
                  </Box>
                  {menuItemActions.length !== 0 && (
                    <IconButton
                      onClick={handleOpenMenu}
                      aria-controls={open ? 'account-menu' : undefined}
                      aria-haspopup="true"
                      aria-expanded={open ? 'true' : undefined}
                      aria-label="acciones"
                      className="comment-menu-trigger"
                      sx={{
                        opacity: open ? 1 : 0,
                        transition: 'opacity 0.2s ease',
                        color: menuTriggerColor,
                        mt: -0.5,
                      }}
                    >
                      <Icono fontSize="small">more_vert</Icono>
                    </IconButton>
                  )}
                </Box>
              </Paper>
            </Box>
          </Box>
          {/* Detalles y acciones */}
          <Box display={'flex'} alignItems={'center'} gap={1.5} pl={7}>
            <Typography variant="caption" color={'text.secondary'}>
              {date ? dayjs(date).fromNow() : ''}
            </Typography>
            {onReply && (
              <Button
                size="small"
                variant="text"
                onClick={handleOpenReply}
                sx={{
                  textTransform: 'none',
                  fontWeight: 500,
                  color: theme.palette.primary.main,
                  p: 0,
                }}
              >
                Responder
              </Button>
            )}
            {onEdit && (
              <Button
                size="small"
                variant="text"
                onClick={handleOpenEdit}
                sx={{
                  textTransform: 'none',
                  fontWeight: 500,
                  color: theme.palette.text.secondary,
                  p: 0,
                }}
              >
                Editar
              </Button>
            )}
          </Box>
          {/* Card para responder */}
          {openReply && (
            <Box pl={5} mt={1}>
              <TipTapWithAvatar
                fullName={userReply.fullName}
                avatarName={userReply.avatarName}
                maxFiles={maxFiles}
                maxFileSizeMB={maxFileSizeMB}
                allowedMimeTypes={allowedMimeTypes}
                onValidationError={onValidationError}
                onAccept={{
                  label: 'Responder',
                  execute: async (payload) => {
                    if (onReply) {
                      await onReply(payload)
                      setOpenReply(false)
                    }
                  },
                }}
                onCancel={{
                  label: 'Cancelar',
                  execute: () => {
                    setOpenReply(false)
                  },
                }}
              />
            </Box>
          )}
        </Box>
      )}

      <Box sx={{ pl: 5, pt: 1 }} position={'relative'}>
        {replies.length !== 0 && (
          <Box
            ref={componentARef}
            borderLeft={'2px solid'}
            sx={{ borderLeftColor: 'divider' }}
            position={'absolute'}
            top={0}
            left={15}
          />
        )}
        {replies.map((reply, index) => (
          <Box
            key={`reply-comment-${index}`}
            position={'relative'}
            ref={index === replies.length - 1 ? componentBRef : undefined}
            pt={1}
          >
            <CardComment
              owner={reply.owner}
              userReply={reply.userReply}
              text={reply.text}
              date={reply.date}
              replies={reply.replies}
              attachments={reply.attachments}
              isOwnMessage={reply.isOwnMessage}
              isEdited={reply.isEdited}
              onEdit={reply.onEdit}
              onReply={reply.onReply}
              menuItemActions={reply.menuItemActions}
              maxFiles={maxFiles}
              maxFileSizeMB={maxFileSizeMB}
              allowedMimeTypes={allowedMimeTypes}
              onValidationError={onValidationError}
            />
            <Box
              height={16}
              width={22}
              borderBottom={'2px solid'}
              borderLeft={'2px solid'}
              sx={{
                borderBottomColor: 'divider',
                borderLeftColor: 'divider',
                borderBottomLeftRadius: '12px',
                position: 'absolute',
                top: '10px',
                left: '-25px',
              }}
            />
          </Box>
        ))}
      </Box>

      <Dialog
        open={isPreviewOpen}
        onClose={handleClosePreview}
        fullWidth
        maxWidth="md"
      >
        <DialogTitle>
          {previewAttachment?.archivo.nombre ?? 'Archivo adjunto'}
        </DialogTitle>
        <DialogContent dividers>
          {renderPreviewContent(previewAttachment) ?? (
            <Typography variant="body2" color="text.secondary">
              No es posible visualizar este tipo de archivo. La descarga se
              iniciará automáticamente.
            </Typography>
          )}
        </DialogContent>
        <DialogActions>
          {previewAttachment && (
            <Button
              variant="outlined"
              onClick={() => {
                void handleDownloadAttachment(
                  previewAttachment.archivo,
                  previewAttachment.objectUrl
                )
              }}
              disabled={attachmentLoadingId === previewAttachment.archivo.id}
              startIcon={
                attachmentLoadingId === previewAttachment.archivo.id ? (
                  <CircularProgress size={16} />
                ) : undefined
              }
            >
              Descargar
            </Button>
          )}
          <Button variant="contained" onClick={handleClosePreview} autoFocus>
            Cerrar
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}

export default CardComment
