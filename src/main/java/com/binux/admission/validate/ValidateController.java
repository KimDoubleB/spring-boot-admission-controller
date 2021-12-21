package com.binux.admission.validate;

import io.fabric8.kubernetes.api.model.Pod;
import io.fabric8.kubernetes.api.model.StatusBuilder;
import io.fabric8.kubernetes.api.model.admission.v1.AdmissionResponseBuilder;
import io.fabric8.kubernetes.api.model.admission.v1.AdmissionReview;
import io.fabric8.kubernetes.api.model.admission.v1.AdmissionReviewBuilder;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
public class ValidateController {

    @PostMapping("/")
    public AdmissionReview validate(@RequestBody AdmissionReview inputAdmissionReview) {
        log.info("Validate called ! : {}", inputAdmissionReview);

        boolean isAllowed;
        String reason;

        var object = inputAdmissionReview.getRequest().getObject();
        var operation = inputAdmissionReview.getRequest().getOperation();

        if (object instanceof Pod && operation.equals("CREATE")) {
            isAllowed = false;
            reason = "Pod create not allowed";
        } else {
            isAllowed = true;
            reason = "Other resources create allowed";
        }

        var admissionResponse = new AdmissionResponseBuilder()
                .withUid(inputAdmissionReview.getRequest().getUid())
                .withAllowed(isAllowed)
                .withStatus(new StatusBuilder().withReason(reason).build())
                .build();

        return new AdmissionReviewBuilder().withResponse(admissionResponse).build();
    }

}
