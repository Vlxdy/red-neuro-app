import { Icono } from '@/components/Icono'
import { Constantes } from '@/config/Constantes'
import { formatFileSize } from '@/utils'
import {
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  Chip,
  CircularProgress,
  IconButton,
  Stack,
  Typography,
} from '@mui/material'
import React, { FC, useEffect, useMemo, useRef, useState } from 'react'
import AvatarCustom from '../../../../../components/avatares/AvatarCustom'
import TipTapCustom from './TipTapCustom'

const EMPTY_CONTENT = ''

const DEFAULT_ALLOWED_MIME_TYPES = [
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/bmp',
  'image/tiff',
  'image/svg+xml',
  'audio/mpeg',
  'audio/aac',
  'audio/wav',
  'audio/ogg',
  'audio/webm',
  'audio/flac',
  'video/mp4',
  'video/webm',
  'video/ogg',
  'video/quicktime',
  'video/x-msvideo',
  'video/mpeg',
]

const sanitizeContent = (value: string) =>
  value
    .replace(/<p><br\/?><\/p>/g, '')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, '')
    .trim()

interface ActionConfig {
  label: string
  execute: (payload: {
    contenido: string
    archivos: File[]
  }) => void | Promise<void>
}

interface TipTapWithAvatarProps {
  avatarName?: string
  fullName: string
  contenido?: string
  onCancel: { label: string; execute: VoidFunction }
  onAccept: ActionConfig
  enableAttachments?: boolean
  maxFiles?: number
  maxFileSizeMB?: number
  allowedMimeTypes?: string[]
  onValidationError?: (mensaje: string) => void
}

const TipTapWithAvatar: FC<TipTapWithAvatarProps> = ({
  fullName,
  avatarName,
  contenido = EMPTY_CONTENT,
  onCancel,
  onAccept,
  enableAttachments = true,
  maxFiles = Constantes.chatMaxFiles,
  maxFileSizeMB = Constantes.chatMaxFileSizeMB,
  allowedMimeTypes = DEFAULT_ALLOWED_MIME_TYPES,
  onValidationError,
}) => {
  const [currentContent, setCurrentContent] = useState<string>(contenido)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const [isSubmitting, setIsSubmitting] = useState(false)
  const fileInputRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    setCurrentContent(contenido)
  }, [contenido])

  useEffect(() => {
    if (!enableAttachments) {
      setSelectedFiles([])
    }
  }, [enableAttachments])

  const maxFileSizeBytes = useMemo(
    () => maxFileSizeMB * 1024 * 1024,
    [maxFileSizeMB]
  )

  const acceptAttribute = useMemo(
    () => allowedMimeTypes.join(','),
    [allowedMimeTypes]
  )

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (!enableAttachments) {
      return
    }

    const incomingFiles = Array.from(event.target.files ?? [])
    if (!incomingFiles.length) {
      return
    }

    const nextFiles: File[] = [...selectedFiles]
    const errores: string[] = []

    for (const file of incomingFiles) {
      if (allowedMimeTypes.length && !allowedMimeTypes.includes(file.type)) {
        errores.push(`El archivo ${file.name} no está permitido.`)
        continue
      }

      if (file.size > maxFileSizeBytes) {
        errores.push(
          `El archivo ${file.name} supera el límite de ${maxFileSizeMB} MB.`
        )
        continue
      }

      if (nextFiles.length >= maxFiles) {
        errores.push(`Solo se permiten ${maxFiles} adjuntos por mensaje.`)
        break
      }

      nextFiles.push(file)
    }

    if (errores.length && onValidationError) {
      onValidationError(errores.join(' '))
    }

    setSelectedFiles(nextFiles)
    if (event.target.value) {
      event.target.value = ''
    }
  }

  const handleRemoveFile = (index: number) => {
    setSelectedFiles((prevFiles) => prevFiles.filter((_, idx) => idx !== index))
  }

  const handleSubmit = async () => {
    if (isSubmitting) {
      return
    }

    const isContentEmpty = sanitizeContent(currentContent).length === 0

    if (isContentEmpty) {
      return
    }

    try {
      setIsSubmitting(true)
      await onAccept.execute({
        contenido: currentContent,
        archivos: selectedFiles,
      })
      setCurrentContent(EMPTY_CONTENT)
      setSelectedFiles([])
    } catch (error) {
      if (onValidationError && error instanceof Error) {
        onValidationError(error.message)
      }
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleCancel = () => {
    onCancel.execute()
    setCurrentContent(contenido)
    setSelectedFiles([])
  }

  const isSubmitDisabled =
    isSubmitting || sanitizeContent(currentContent).length === 0

  return (
    <Box display={'flex'} gap={1} mb={2}>
      <AvatarCustom fullName={fullName} avatarName={avatarName} size="small" />
      <Box flexGrow={1}>
        <Card sx={{ borderRadius: 3, pb: 0 }} variant="outlined">
          <CardHeader
            action={
              <IconButton onClick={handleCancel} aria-label={onCancel.label}>
                <Icono fontSize="small">close</Icono>
              </IconButton>
            }
            title={
              <Box>
                <Typography variant="body2" fontWeight={'medium'}>
                  {fullName}
                </Typography>
              </Box>
            }
            sx={{ p: 1 }}
          />
          <CardContent sx={{ px: 1, pt: 0, paddingBottom: '8px !important' }}>
            <Box>
              <TipTapCustom
                mostrarOpcionesAlineacion={false}
                mostrarOpcionesTabla={false}
                mostrarOpcionesURL={false}
                editable={true}
                contenido={currentContent}
                onChange={(contenidoNuevo) => {
                  setCurrentContent(contenidoNuevo)
                }}
              />
            </Box>

            {enableAttachments && (
              <Box mt={1}>
                <input
                  ref={fileInputRef}
                  type="file"
                  hidden
                  multiple
                  accept={acceptAttribute}
                  onChange={handleFileChange}
                />
                <Button
                  size="small"
                  variant="text"
                  startIcon={<Icono fontSize="small">attach_file</Icono>}
                  onClick={() => fileInputRef.current?.click()}
                >
                  Adjuntar archivo
                </Button>
                {selectedFiles.length > 0 && (
                  <Stack
                    direction="column"
                    spacing={1}
                    mt={1}
                    sx={{ maxHeight: 120, overflowY: 'auto' }}
                  >
                    {selectedFiles.map((file, index) => (
                      <Chip
                        key={`${file.name}-${index}`}
                        label={`${file.name} · ${formatFileSize(file.size)}`}
                        onDelete={() => handleRemoveFile(index)}
                        deleteIcon={<Icono fontSize="small">close</Icono>}
                        variant="outlined"
                      />
                    ))}
                  </Stack>
                )}
                <Typography
                  variant="caption"
                  color="text.secondary"
                  mt={1}
                  display="block"
                >
                  Máximo {maxFiles} archivos · {maxFileSizeMB} MB c/u
                </Typography>
              </Box>
            )}

            <Box display={'flex'} gap={1} justifyContent={'flex-end'} mt={1}>
              <Button
                disabled={isSubmitDisabled}
                variant={'contained'}
                size="small"
                startIcon={
                  isSubmitting ? (
                    <CircularProgress size={16} color="inherit" />
                  ) : undefined
                }
                onClick={() => {
                  void handleSubmit()
                }}
              >
                {onAccept.label}
              </Button>
            </Box>
          </CardContent>
        </Card>
      </Box>
    </Box>
  )
}

export default TipTapWithAvatar
