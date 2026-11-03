package com.liverpool.pms.controller;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.liverpool.pms.model.Sponsorship;
import com.liverpool.pms.service.SponsorshipService;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.util.List;

@RestController
@RequestMapping("/api/sponsorships")
@CrossOrigin(origins = "*")
public class SponsorshipController {

    private final SponsorshipService sponsorshipService;
    private final ObjectMapper objectMapper;

    public SponsorshipController(
            SponsorshipService sponsorshipService,
            ObjectMapper objectMapper) {
        this.sponsorshipService = sponsorshipService;
        this.objectMapper = objectMapper;
    }

    @GetMapping
    public ResponseEntity<List<Sponsorship>> getAll() {
        return ResponseEntity.ok(sponsorshipService.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Sponsorship> getById(@PathVariable String id) {
        return ResponseEntity.ok(sponsorshipService.getById(id));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Sponsorship> create(
            @RequestParam("sponsorship") String sponsorshipJson,
            @RequestPart(value = "contract", required = false) MultipartFile contract) {
        Sponsorship created = sponsorshipService.create(
                parse(sponsorshipJson),
                contract == null ? null : contract.getOriginalFilename(),
                bytes(contract));
        return ResponseEntity.status(201).body(created);
    }

    @PutMapping(value = "/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Sponsorship> update(
            @PathVariable String id,
            @RequestParam("sponsorship") String sponsorshipJson,
            @RequestPart(value = "contract", required = false) MultipartFile contract) {
        Sponsorship updated = sponsorshipService.update(
                id,
                parse(sponsorshipJson),
                contract == null ? null : contract.getOriginalFilename(),
                bytes(contract));
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        sponsorshipService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/contract")
    public ResponseEntity<ByteArrayResource> getContract(@PathVariable String id) {
        Sponsorship sponsorship = sponsorshipService.getById(id);
        byte[] content = sponsorshipService.getContract(id);
        String filename = sponsorship.getContractFileName();
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .contentLength(content.length)
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                        .filename(filename, StandardCharsets.UTF_8)
                        .build().toString())
                .body(new ByteArrayResource(content));
    }

    private Sponsorship parse(String json) {
        try {
            return objectMapper.readValue(json, Sponsorship.class);
        } catch (JsonProcessingException exception) {
            throw new ResponseStatusException(400, "Invalid sponsorship JSON", exception);
        }
    }

    private byte[] bytes(MultipartFile contract) {
        if (contract == null || contract.isEmpty()) {
            return null;
        }
        try {
            return contract.getBytes();
        } catch (java.io.IOException exception) {
            throw new ResponseStatusException(400, "Unable to read contract file", exception);
        }
    }
}
